/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/__tests__/**/*.test.(ts|js)'],
  passWithNoTests: true,
  moduleFileExtensions: ['ts', 'js', 'json']
};

