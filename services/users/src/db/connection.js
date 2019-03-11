const path = require('path');
const config = {
  client: 'pg',
  connection: process.env.DATABASE_URL,
  migrations: {
    directory: path.join(__dirname, 'migrations')
  },
  seeds: {
    directory: path.join(__dirname, 'seeds')
  }
}

const knex = require('knex')(config);

knex.migrate.make('init');
knex.migrate.latest();

module.exports = knex;
