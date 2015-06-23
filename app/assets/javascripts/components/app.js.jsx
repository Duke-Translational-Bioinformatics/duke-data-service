var App = React.createClass({
  getInitialState: function() {
    return {
      access_token: '',
      api_token: ''
    };
  },
  componentDidMount: function() {
    if (window.location.href.indexOf('#access_token') > 0){
      var parts = window.location.hash.split('&');
      this.setState({access_token: parts[0].split('=')[1]});
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
