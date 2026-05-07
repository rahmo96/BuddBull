const express = require('express');

const MapsController = require('../controllers/maps.controller');
const { validate } = require('../validators/game.validator');
const {
  autocompleteSchema,
  placeDetailsSchema,
  staticMapSchema,
} = require('../validators/maps.validator');

const router = express.Router();

router.get('/autocomplete', validate(autocompleteSchema, 'query'), MapsController.autocompleteAddress);
router.get('/place-details', validate(placeDetailsSchema, 'query'), MapsController.getPlaceDetails);
router.get('/static', validate(staticMapSchema, 'query'), MapsController.getStaticMap);

module.exports = router;
