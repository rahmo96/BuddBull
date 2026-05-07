const AppError = require('../utils/AppError');

const GOOGLE_PLACES_AUTOCOMPLETE_URL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
const GOOGLE_PLACES_DETAILS_URL = 'https://maps.googleapis.com/maps/api/place/details/json';
const GOOGLE_STATIC_MAP_URL = 'https://maps.googleapis.com/maps/api/staticmap';

const apiKey = process.env.GOOGLE_MAPS_API_KEY || '';

const ensureApiKey = () => {
  if (!apiKey) {
    throw new AppError('Google Maps API key is not configured.', 500);
  }
};

const getJson = async (baseUrl, params) => {
  ensureApiKey();
  const url = new URL(baseUrl);
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && `${value}`.trim().length > 0) {
      url.searchParams.set(key, `${value}`);
    }
  });
  url.searchParams.set('key', apiKey);

  const response = await globalThis.fetch(url.toString());
  if (!response.ok) {
    throw new AppError('Google Maps request failed.', 502);
  }
  return response.json();
};

const toAddressParts = (components = []) => {
  const findByType = (type) =>
    components.find((component) => Array.isArray(component.types) && component.types.includes(type));

  const city = findByType('locality')?.long_name
    || findByType('postal_town')?.long_name
    || findByType('administrative_area_level_2')?.long_name
    || '';

  const neighborhood = findByType('neighborhood')?.long_name
    || findByType('sublocality')?.long_name
    || findByType('sublocality_level_1')?.long_name
    || city;

  const state = findByType('administrative_area_level_1')?.short_name;
  const country = findByType('country')?.short_name;
  const postalCode = findByType('postal_code')?.long_name;

  return {
    city,
    neighborhood,
    state,
    country,
    postalCode,
  };
};

const autocompleteAddress = async ({ input, sessionToken }) => {
  const body = await getJson(GOOGLE_PLACES_AUTOCOMPLETE_URL, {
    input,
    types: 'address',
    sessiontoken: sessionToken || undefined,
  });

  if (body.status !== 'OK' && body.status !== 'ZERO_RESULTS') {
    throw new AppError(body.error_message || 'Address autocomplete failed.', 502);
  }

  const suggestions = (body.predictions || []).map((prediction) => ({
    placeId: prediction.place_id,
    description: prediction.description,
    primaryText: prediction.structured_formatting?.main_text || prediction.description,
    secondaryText: prediction.structured_formatting?.secondary_text || '',
  }));

  return suggestions;
};

const getPlaceDetails = async ({ placeId, sessionToken }) => {
  const body = await getJson(GOOGLE_PLACES_DETAILS_URL, {
    place_id: placeId,
    fields: 'place_id,name,formatted_address,geometry,address_component',
    sessiontoken: sessionToken || undefined,
  });

  if (body.status !== 'OK' || !body.result) {
    throw new AppError(body.error_message || 'Address details lookup failed.', 502);
  }

  const result = body.result;
  const lat = result.geometry?.location?.lat;
  const lng = result.geometry?.location?.lng;
  if (typeof lat !== 'number' || typeof lng !== 'number') {
    throw new AppError('Selected place does not include valid coordinates.', 422);
  }

  const parts = toAddressParts(result.address_components);
  if (!parts.city || !parts.neighborhood) {
    throw new AppError('Selected address is missing city or neighborhood.', 422);
  }

  return {
    placeId: result.place_id,
    venueName: result.name || null,
    formattedAddress: result.formatted_address || '',
    address: result.formatted_address || '',
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

const getStaticMapImage = async ({
  lat, lng, zoom, width, height,
}) => {
  ensureApiKey();
  const url = new URL(GOOGLE_STATIC_MAP_URL);
  url.searchParams.set('center', `${lat},${lng}`);
  url.searchParams.set('zoom', `${zoom}`);
  url.searchParams.set('size', `${width}x${height}`);
  url.searchParams.set('markers', `color:red|${lat},${lng}`);
  url.searchParams.set('maptype', 'roadmap');
  url.searchParams.set('key', apiKey);

  const response = await globalThis.fetch(url.toString());
  if (!response.ok) {
    throw new AppError('Could not load static map image.', 502);
  }

  const contentType = response.headers.get('content-type') || 'image/png';
  const arrayBuffer = await response.arrayBuffer();

  return {
    bytes: Buffer.from(arrayBuffer),
    contentType,
  };
};

module.exports = {
  autocompleteAddress,
  getPlaceDetails,
  getStaticMapImage,
};
