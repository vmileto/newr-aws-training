const newrelic = require('newrelic');
const request = require('request-promise');

let ensureAuthenticated = (req, res, next) => {
  if (!(req.headers && req.headers.authorization)) {
    return res.status(400).json({ status: 'Please log in' });
  }
  const options = {
    method: 'GET',
    uri: `${process.env.USERS_SERVICE_URL}/users/user`,
    json: true,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${req.headers.authorization.split(' ')[1]}`,
    },
  };
  return request(options)
  .then((response) => {
    req.user = response.user;
    req.username = response.username;
    newrelic.addCustomAttribute('ar_username', response.username);
    return next();
  })
  .catch((err) => { return next(err); });
};

if (process.env.NODE_ENV === 'test') {
  ensureAuthenticated = (req, res, next) => {
    req.user = 1;
    req.username = 'zappa';
    return next();
  };
}

module.exports = {
  ensureAuthenticated,
};
