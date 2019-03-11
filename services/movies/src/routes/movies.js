const newrelic = require('newrelic');
const express = require('express');

const queries = require('../db/queries.js');
const authHelpers = require('./_helpers');

const router = express.Router();

router.get('/ping', (req, res) => {
  res.send('pong');
});

/*
get movies by user
 */
/* eslint-disable no-param-reassign */
router.get('/user', authHelpers.ensureAuthenticated, (req, res, next) => {
  const username = req.username;
  return queries.getSavedMovies(parseInt(req.user, 10))
  .then((movies) => {
    //newrelic.addCustomAttribute('ar_username', username);
    //newrelic.addCustomAttribute('ar_collection_count', movies.length);
    res.json({
      status: 'success',
      data: movies,
    });
  })
  .catch((err) => {
    newrelic.noticeError(err, [req.user]);
    return next(err);
  });
});
/* eslint-enable no-param-reassign */

/*
add new movie
 */
router.post('/', authHelpers.ensureAuthenticated, (req, res, next) => {
  const username = req.username;
  const title = req.body.title;
  req.body.user_id = req.user;
  return queries.addMovie(req.body)
  .then(() => {
    //newrelic.addCustomAttribute('ar_username', username);
    newrelic.recordCustomEvent('MoviesCatalog', {'ar_username': username, 'ar_title': title});
    res.json({
      status: 'success',
      data: 'Movie Added!',
    });
  })
  .catch((err) => {
    newrelic.noticeError(err, [req.user]);
    return next(err);
  });
});

module.exports = router;
