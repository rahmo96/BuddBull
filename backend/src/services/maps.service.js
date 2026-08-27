const AppError = require('../utils/AppError');

const GOOGLE_PLACES_AUTOCOMPLETE_URL = 'https://places.googleapis.com/v1/places:autocomplete';
const GOOGLE_PLACES_DETAILS_URL = 'https://places.googleapis.com/v1/places';
const GOOGLE_STATIC_MAP_URL = 'https://maps.googleapis.com/maps/api/staticmap';

const getApiKey = () => process.env.GOOGLE_MAPS_API_KEY || '';

const ensureApiKey = () => {
  if (!getApiKey()) {
    throw new AppError('Google Maps API key is not configured.', 500);
  }
};

const googleErrorMessage = async (response) => {
  try {
    const body = await response.json();
    return body?.error?.message || body?.error_message || null;
  } catch {
    return null;
  }
};

/**
 * Map legacy Places `types` query values to Places API (New) includedPrimaryTypes.
 * @param {string|undefined} types
 * @returns {string[]|undefined}
 */
const toIncludedPrimaryTypes = (types) => {
  const raw = `${types || ''}`.trim();
  if (!raw) return undefined;
  if (raw === 'address') return ['street_address', 'premise', 'subpremise'];
  if (raw === '(cities)' || raw === '(regions)') return [raw];
  const list = raw
    .split('|')
    .map((t) => t.trim())
    .filter(Boolean)
    .slice(0, 5);
  return list.length ? list : undefined;
};

const toAddressParts = (components = []) => {
  const findByType = (type) =>
    components.find((component) => Array.isArray(component.types) && component.types.includes(type));

  const longName = (component) => component?.longText || component?.long_name || '';
  const shortName = (component) => component?.shortText || component?.short_name || '';

  const city =
    longName(findByType('locality')) ||
    longName(findByType('postal_town')) ||
    longName(findByType('administrative_area_level_2')) ||
    '';

  const neighborhood =
    longName(findByType('neighborhood')) ||
    longName(findByType('sublocality')) ||
    longName(findByType('sublocality_level_1')) ||
    city;

  const state = shortName(findByType('administrative_area_level_1')) || null;
  const country = shortName(findByType('country')) || null;
  const postalCode = longName(findByType('postal_code')) || null;

  return {
    city,
    neighborhood,
    state,
    country,
    postalCode: postalCode || null,
  };
};

const autocompleteAddress = async ({ input, sessionToken, types }) => {
  ensureApiKey();

  const requestBody = {
    input,
  };
  const includedPrimaryTypes = toIncludedPrimaryTypes(types);
  if (includedPrimaryTypes) {
    requestBody.includedPrimaryTypes = includedPrimaryTypes;
  }
  if (sessionToken && `${sessionToken}`.trim()) {
    requestBody.sessionToken = `${sessionToken}`.trim();
  }

  const response = await globalThis.fetch(GOOGLE_PLACES_AUTOCOMPLETE_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': getApiKey(),
      'X-Goog-FieldMask':
        'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const message = await googleErrorMessage(response);
    throw new AppError(message || 'Address autocomplete failed.', 502);
  }

  const body = await response.json();
  const suggestions = (body.suggestions || [])
    .map((item) => item.placePrediction)
    .filter(Boolean)
    .map((prediction) => {
      const description = prediction.text?.text || '';
      const primaryText =
        prediction.structuredFormat?.mainText?.text || description;
      const secondaryText = prediction.structuredFormat?.secondaryText?.text || '';
      return {
        placeId: prediction.placeId,
        description,
        primaryText,
        secondaryText,
      };
    });

  return suggestions;
};

const normalizePlaceId = (placeId) => {
  const raw = `${placeId || ''}`.trim();
  if (!raw) return '';
  return raw.startsWith('places/') ? raw.slice('places/'.length) : raw;
};

const getPlaceDetails = async ({ placeId, sessionToken }) => {
  ensureApiKey();

  const id = normalizePlaceId(placeId);
  if (!id) {
    throw new AppError('placeId is required.', 400);
  }

  const url = new URL(`${GOOGLE_PLACES_DETAILS_URL}/${encodeURIComponent(id)}`);
  if (sessionToken && `${sessionToken}`.trim()) {
    url.searchParams.set('sessionToken', `${sessionToken}`.trim());
  }

  const response = await globalThis.fetch(url.toString(), {
    method: 'GET',
    headers: {
      'X-Goog-Api-Key': getApiKey(),
      'X-Goog-FieldMask':
        'id,displayName,formattedAddress,location,addressComponents',
    },
  });

  if (!response.ok) {
    const message = await googleErrorMessage(response);
    throw new AppError(message || 'Address details lookup failed.', 502);
  }

  const result = await response.json();
  const lat = result.location?.latitude;
  const lng = result.location?.longitude;
  if (typeof lat !== 'number' || typeof lng !== 'number') {
    throw new AppError('Selected place does not include valid coordinates.', 422);
  }

  const parts = toAddressParts(result.addressComponents || []);
  if (!parts.city || !parts.neighborhood) {
    throw new AppError('Selected address is missing city or neighborhood.', 422);
  }

  return {
    placeId: result.id || id,
    venueName: result.displayName?.text || null,
    formattedAddress: result.formattedAddress || '',
    address: result.formattedAddress || '',
    city: parts.city,
    neighborhood: parts.neighborhood,
    state: parts.state || null,
    country: parts.country || null,
    postalCode: parts.postalCode || null,
    coordinates: {
      type: 'Point',
      coordinates: [lng, lat],
    },
  };
};

const getStaticMapImage = async ({ lat, lng, zoom, width, height }) => {
  ensureApiKey();
  const url = new URL(GOOGLE_STATIC_MAP_URL);
  url.searchParams.set('center', `${lat},${lng}`);
  url.searchParams.set('zoom', `${zoom}`);
  url.searchParams.set('size', `${width}x${height}`);
  url.searchParams.set('markers', `color:red|${lat},${lng}`);
  url.searchParams.set('maptype', 'roadmap');
  url.searchParams.set('key', getApiKey());

  const response = await globalThis.fetch(url.toString());
  const contentType = response.headers.get('content-type') || '';

  if (!response.ok || !contentType.startsWith('image/')) {
    let message = 'Could not load static map image.';
    if (contentType.includes('json') || contentType.includes('text')) {
      try {
        const text = await response.text();
        const parsed = JSON.parse(text);
        message = parsed?.error_message || parsed?.error?.message || text.slice(0, 200) || message;
      } catch {
        // keep default message
      }
    }
    throw new AppError(message, 502);
  }

  const arrayBuffer = await response.arrayBuffer();

  return {
    bytes: Buffer.from(arrayBuffer),
    contentType: contentType || 'image/png',
  };
};

module.exports = {
  autocompleteAddress,
  getPlaceDetails,
  getStaticMapImage,
};
