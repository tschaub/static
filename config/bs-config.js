
/**
 * BrowserSync configuration.
 * See http://www.browsersync.io/docs/options/
 */
module.exports = {
  files: 'build/dev/**',
  server: {
    baseDir: 'build/dev'
  },
  open: false
};
