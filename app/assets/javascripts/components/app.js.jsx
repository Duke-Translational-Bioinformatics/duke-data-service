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
        <h1>App {this.props.foo}</h1>
        <p>access_token: {this.state.access_token}</p>
        <Child page={this.props.foo} />
      </div>
    )
  }
});
