module.exports = {
  env: {
    node: true,
    es2021: true,
    jest: true,
  },
  extends: ['airbnb-base'],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  rules: {
    // Allow underscore-prefixed identifiers (common in Mongoose for _id)
    'no-underscore-dangle': ['error', { allow: ['_id', '__v'] }],

    // Prefer named exports but allow default in model files
    'import/prefer-default-export': 'off',

    // Console allowed only via the logger utility; disable raw console
    'no-console': 'error',

    // Arrow function body braces — keep consistent
    'arrow-body-style': ['error', 'as-needed'],

    // Enforce max line length for readability
    'max-len': ['warn', { code: 120, ignoreComments: true, ignoreStrings: true }],

    // Allow async/await in forEach (common but must be intentional)
    'no-await-in-loop': 'warn',

    // Mongoose virtuals / pre hooks use `this`
    'func-names': 'off',

    // Allow multiple return statements in complex service logic
    'consistent-return': 'off',

    // Destructuring not always practical
    'prefer-destructuring': ['warn', { object: true, array: false }],

    // Allow param reassignment for Express middleware pattern (req.user = ...)
    'no-param-reassign': ['error', { props: true, ignorePropertyModificationsFor: ['req', 'res', 'next'] }],
  },
};
