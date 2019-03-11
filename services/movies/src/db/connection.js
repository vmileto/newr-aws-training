const path = require('path');
const knex = require('knex')({
  client: 'pg',
  connection: process.env.DATABASE_URL,
  migrations: {
    directory: path.join(__dirname, 'migrations')
  },
  seeds: {
    directory: path.join(__dirname, 'seeds')
  }
});

knex.migrate.make('init');
knex.migrate.latest();

module.exports = knex;
