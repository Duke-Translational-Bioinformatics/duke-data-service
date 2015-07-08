/** @jsx React.DOM */
var RouteHandler = ReactRouter.RouteHandler;
var Navigation = ReactRouter.Navigation;

var App = React.createClass({
  mixins: [ Navigation ],

  setMainMenuItems: function(menuItems) {
    this.setState({menuItems:
      menuItems.concat([
        {content: <a><i className="fa fa-info-circle fa-2x" /> About</a>},
        {content: <a>Terms & Conditions</a>}
      ])
    });
  },

  handleLogout: function() {
    window.localStorage.removeItem('api_token');
    this.transitionTo('home');
  },

  handleExpiredToken: function(info) {
    this.handleLogout();
    this.alertUser(info);
  },

  alertUser: function(alertInfo) {
   React.render(
     <div className="alert alert-danger alert-dismissible" role="alert">
       <button type="button" className="close" data-dismiss="alert" aria-label="Close">
         <span aria-hidden="true">&times;</span>
       </button>
       <strong>{alertInfo["reason"]}</strong> {alertInfo["suggestion"]}.
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
    console.log("ERROR "+errorMessage);
  },

  getApiToken: function(signed_token) {
    return $.ajax({
      type: 'GET',
      url: '/api/v1/user/api_token?access_token='+signed_token,
      contentType: 'application/json',
      dataType: 'json'
    })
  },

  handleAjaxError: function(jqXHR, status, err) {
    switch(jqXHR.status) {
    case 401:
      this.handleExpiredToken(JSON.parse(jqXHR.responseText));
      break;
    case 400:
      this.handleValidationErrors(JSON.parse(jqXHR.responseText));
      break;
    default:
      console.log("Unexpected error: "+jqXHR.responseText);
      break;
    }
  },

  handleValidationErrors: function(errorInfo) {
    this.alertUser(errorInfo);
    if (errorInfo["reason"] == "validation failed") {
      errorInfo["errors"].map(function(validation_error) {
        var invalid_field = validation_error["field"];
        var message = validation_error["message"];
        $("#"+invalid_field+"Field").addClass('has-error');
        React.render(
          <div className="alert alert-danger alert-dismissible" role="alert">
            <button type="button" className="close" data-dismiss="alert" aria-label="Close">
              <span aria-hidden="true">&times;</span>
            </button>
            {message}.
          </div>
          , document.getElementById(invalid_field+'Alert')
        );

      });
    }
    else {
      console.log("Unexpected 400 Error "+JSON.stringify(errorInfo));
    }
  },

  getResourceWithToken: function(api_token, resourceUrl) {
     return $.ajax({
       type: 'GET',
       url: resourceUrl,
       beforeSend: function(xhr) {
         xhr.setRequestHeader("Authorization", api_token);
       },
       contentType: 'application/json',
       dataType: 'json'
     })
  },

  getCurrentUser: function(api_token) {
    return this.getResourceWithToken(api_token, '/api/v1/current_user');
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
      currentUser: '',
      menuItems: []
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
        this.handleAjaxError
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
                  this.handleAjaxError
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
    var itemKey = 0;
    return (
      <div className="container-fluid App">
        <NavMenu
           {...this.props}
           currentUser={this.state.currentUser}
           isLoggedIn={this.state.isLoggedIn}
           handleLogout={this.handleLogout}>
           {this.state.menuItems.map(function(menuItem) {
             itemKey = itemKey + 1;
             if (menuItem.link_to) {
               return <li key={itemKey}><Link to={menuItem.link_to} params={menuItem.link_params}>{menuItem.content}</Link></li>
             }
             else {
               return <li key={itemKey}>{menuItem.content}</li>
             }
           })}
        </NavMenu>
        <div id="alerts" />
        <div>
          <RouteHandler {...this.props}
                        {...this.state}
                        setMainMenuItems={this.setMainMenuItems}
                        getResourceWithToken={this.getResourceWithToken}
                        handleAjaxError={this.handleAjaxError}
                        />
        </div>
      </div>
    )
  }
});
