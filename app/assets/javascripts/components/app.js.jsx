/** @jsx React.DOM */
var RouteHandler = ReactRouter.RouteHandler;
var Navigation = ReactRouter.Navigation;

var App = React.createClass({
  mixins: [ Navigation ],

  contextTypes: {
    router: React.PropTypes.func
  },

  handleLogout: function() {
    window.localStorage.removeItem('api_token');
    this.replaceWith('home');
  },
  validateAccessToken: function(access_token) {
    var jqReq = $.ajax({
      type: 'GET',
      url: this.props.auth_service_uri+'/api/v1/token_info?access_token='+access_token,
      contentType: 'application/json',
      dataType: 'json'
    }).then(
      function(data) {
        signed_token = data['signed_info'];
        this.setApiToken(signed_token);
      }.bind(this),
      function(jqXHR, status, err) {
        console.log(jqXHR.responseText);
        var errorMessage = JSON.parse(jqXHR.responseText);
        console.log("ERROR "+errorMessage)
      }.bind(this)
    );
  },
  setApiToken: function(signed_token) {
    var jqReq = $.ajax({
      type: 'GET',
      url: '/api/v1/user/api_token?access_token='+signed_token,
      contentType: 'application/json',
      dataType: 'json'
    }).then(
      function(data) {
        api_token = data['api_token'];
        window.localStorage.api_token = api_token;
        this.setState({
          api_token: api_token,
          isLoggedIn: true
        });
      }.bind(this),
      function(jqXHR, status, err) {
        console.log(jqXHR.responseText);
        var errorMessage = JSON.parse(jqXHR.responseText);
        console.log("ERROR "+errorMessage)
      }.bind(this)
    );
  },
  getInitialState: function() {
    return {
      api_token: '',
      isLoggedIn: false
    };
  },

  componentDidMount: function() {
    if (window.localStorage.api_token) {
      this.setState({
        api_token: window.localStorage.api_token,
        isLoggedIn: true
      });
    }
    else {
      if (window.location.href.indexOf('#access_token') > 0){
        var parts = window.location.hash.split('&');
        var access_token = parts[0].split('=')[1];
        this.validateAccessToken(access_token);
      }
    }
  },
  render: function() {
    return (
      <div>
        <NavMenu {...this.props} isLoggedIn={this.state.isLoggedIn} handleLogout={this.handleLogout} />
        <div className="container-fluid">
          <RouteHandler {...this.props} {...this.state} />
        </div>
      </div>
    )
  }
});
