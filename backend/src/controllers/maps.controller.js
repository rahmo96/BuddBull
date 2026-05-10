const catchAsync = require('../utils/catchAsync');
const MapsService = require('../services/maps.service');

const autocompleteAddress = catchAsync(async (req, res) => {
  const suggestions = await MapsService.autocompleteAddress(req.query);
  res.status(200).json({ success: true, data: { suggestions } });
});

const getPlaceDetails = catchAsync(async (req, res) => {
  const location = await MapsService.getPlaceDetails(req.query);
  res.status(200).json({ success: true, data: { location } });
});

const getStaticMap = catchAsync(async (req, res) => {
  const { lat, lng, zoom, width, height } = req.query;
  const image = await MapsService.getStaticMapImage({
    lat: Number(lat),
    lng: Number(lng),
    zoom: Number(zoom),
    width: Number(width),
    height: Number(height),
  });

  res.setHeader('Content-Type', image.contentType);
  res.setHeader('Cache-Control', 'public, max-age=86400');
  res.status(200).send(image.bytes);
});

module.exports = {
  autocompleteAddress,
  getPlaceDetails,
  getStaticMap,
};
