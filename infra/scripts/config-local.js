define([], function () {
  var configLocal = {};

  // clearing local storage otherwise source cache will obscure the override settings
  localStorage.clear();

  // WebAPI
  configLocal.api = {
    name: "OHDSI",
    url: "$OHDSI_WEBAPI_URL",
  };

  configLocal.cohortComparisonResultsEnabled = false;
  configLocal.userAuthenticationEnabled = true;
  configLocal.plpResultsEnabled = false;

  configLocal.authProviders = [
    {
      name: "Local Security Test DB",
      url: "user/login/db",
      ajax: true,
      icon: "fa fa-database",
      isUseCredentialsForm: true,
    },
    {
      name: "SAML",
      url: "user/login/saml",
      ajax: false,
      icon: "fab fa-openid"
    },
  ];

  return configLocal;
});
