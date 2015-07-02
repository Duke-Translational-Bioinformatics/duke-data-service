/** @jsx React.DOM */
var RouteHandler = ReactRouter.RouteHandler;
var Navigation = ReactRouter.Navigation;

var App = React.createClass({
  mixins: [ Navigation ],

  handleLogout: function() {
    window.localStorage.removeItem('api_token');
    this.transitionTo('home');
  },

  handleExpiredToken: function(info) {
    //TODO display an error message
    console.log("Expired Token "+info["reason"]+" suggestion "+info["suggestion"]);
    this.handleLogout();
    this.alertUser(info);
  },

  alertUser: function(alertInfo) {
   React.render(
     <div className="alert alert-warning alert-dismissible" role="alert">
       <button type="button" className="close" data-dismiss="alert" aria-label="Close">
         <span aria-hidden="true">&times;</span>
       </button>
       <strong>{alertInfo["reason"]}</strong>{alertInfo["suggestion"]}.
     </div>
     , document.getElementById('alerts')
   );
  },

  handleInvalidAccessToken: function(jqXHR, status, err) {
    console.log(jqXHR.responseText);
    var errorMessage = JSON.parse(jqXHR.responseText);
    console.log("ERROR "+errorMessage)
    this.handleLogout();
  },

  validateAccessToken: function(access_token) {
    return $.ajax({
      type: 'GET',
      url: this.props.auth_service_uri+'/api/v1/token_info?access_token='+access_token,
      contentType: 'application/json',
      dataType: 'json'
    })
  },

  handleInvalidSignedToken: function(jqXHR, status, err) {
    console.log(jqXHR.responseText);
    var errorMessage = JSON.parse(jqXHR.responseText);
    console.log("ERROR "+errorMessage)
  },

  getApiToken: function(signed_token) {
    return $.ajax({
      type: 'GET',
      url: '/api/v1/user/api_token?access_token='+signed_token,
      contentType: 'application/json',
      dataType: 'json'
    })
  },

  handleCurrentUserError: function(jqXHR, status, err) {
    console.log("GOT status "+jqXHR.status);
    if (jqXHR.status == 401) {
      this.handleExpiredToken(JSON.parse(jqXHR.responseText));
    }
  },

  getCurrentUser: function(api_token) {
    return $.ajax({
      type: 'GET',
      url: '/api/v1/current_user',
      beforeSend: function(xhr) {
        xhr.setRequestHeader("Authorization", api_token);
      },
      contentType: 'application/json',
      dataType: 'json'
    })
  },

  loadCurrentUser: function(data) {
    if (this.isMounted()) {
      this.setState({
        currentUser: data,
        isLoggedIn: true
      });
    }
  },

  getInitialState: function() {
    return {
      api_token: '',
      isLoggedIn: false,
      currentUser: ''
    };
  },

  componentDidMount: function() {
    var api_token = window.localStorage.api_token;
    if (api_token) {
      if (this.isMounted()) {
        this.setState({api_token: api_token});
      }
      this.getCurrentUser(api_token).then(
        this.loadCurrentUser,
        this.handleCurrentUserError
      );
    }
    else {
      if (window.location.href.indexOf('#access_token') > 0){
        var parts = window.location.hash.split('&');
        var access_token = parts[0].split('=')[1];
        this.validateAccessToken(access_token).then(
          function(data) {
            signed_token = data['signed_info'];
            this.getApiToken(signed_token).then(
              function(data) {
                api_token = data['api_token'];
                window.localStorage.api_token = api_token;
                if (this.isMounted()) {
                  this.setState({api_token: api_token});
                }
                this.getCurrentUser(api_token).then(
                  this.loadCurrentUser,
                  this.handleCurrentUserError
                );
              }.bind(this),
              this.handleInvalidSignedToken
            );
          }.bind(this),
          this.handleInvalidAccessToken
        );
        window.location.replace("#");
        if (typeof window.history.replaceState == 'function') {
          history.replaceState({}, '', window.location.href.slice(0, -1));
        }
        this.transitionTo('home');
      }
    }
  },

  render: function() {
    return (
      <div className="container-fluid">
        <NavMenu {...this.props} currentUser={this.state.currentUser} isLoggedIn={this.state.isLoggedIn} handleLogout={this.handleLogout} />
        <div className="row">
          <div id="alerts" />
          <RouteHandler {...this.props} {...this.state} />
        </div>
      </div>
    )
  }
});
