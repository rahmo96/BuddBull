const Joi = require('joi');

const autocompleteSchema = Joi.object({
  input: Joi.string().trim().min(3).max(200).required(),
  sessionToken: Joi.string().trim().max(200).allow('', null),
});

const placeDetailsSchema = Joi.object({
  placeId: Joi.string().trim().required(),
  sessionToken: Joi.string().trim().max(200).allow('', null),
});

const staticMapSchema = Joi.object({
  lat: Joi.number().min(-90).max(90).required(),
  lng: Joi.number().min(-180).max(180).required(),
  zoom: Joi.number().integer().min(8).max(19).default(14),
  width: Joi.number().integer().min(200).max(1280).default(900),
  height: Joi.number().integer().min(120).max(1280).default(360),
});

module.exports = {
  autocompleteSchema,
  placeDetailsSchema,
  staticMapSchema,
};
