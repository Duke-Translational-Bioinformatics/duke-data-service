var App = React.createClass({
  validateAccessToken: function(access_token) {
    var jqReq = $.ajax({
      type: 'GET',
      url: this.props.auth_service_uri+'/api/v1/token_info?access_token='+access_token,
      contentType: 'application/json',
      dataType: 'json'
    }).then(
      function(data) {
        
      },
      function(jqXHR, status, err) {
        console.log(jqXHR.responseText);
        var errorMessage = JSON.parse(jqXHR.responseText);
        console.log("ERROR "+errorMessage)
      }.bind(this)
    );
  },
  getInitialState: function() {
    return {
      access_token: '',
      api_token: ''
    };
  },
  componentDidMount: function() {
    if (window.location.href.indexOf('#access_token') > 0){
      var parts = window.location.hash.split('&');
      var access_token = parts[0].split('=')[1];
      this.setState({access_token: access_token});
      this.validateAccessToken(access_token);
    }
  },
  render: function() {
    var Child;
    if (this.state.api_token.length > 0) {
      Child = Home;
    }
    else {
      Child = Login;
    }
    return (
      <div>
        <h1>Duke Data Services</h1>
        <p>access_token: {this.state.access_token}</p>
        <Child service_id={this.props.service_id} auth_service_name={this.props.auth_service_name} auth_service_uri={this.props.auth_service_uri} />
      </div>
    )
  }
});
