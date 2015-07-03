var Login = React.createClass({
    componentDidMount: function() {
      this.setState({security_state: $('meta[name="csrf-token"]').attr('content')});
    },
    getInitialState: function() {
    return {
      security_state: ''
    };
  },
  render: function() {
    return (
      <div className="Login">
        <h5>Please login with an Authentication Service</h5>
        <ul>
          <li><a href={this.props.auth_service_uri+"/authenticate?client_id="+this.props.service_id+"&state="+this.state.security_state+"&response_type=Bearer&scope=display_name mail uid"}>{this.props.auth_service_name}</a></li>
        </ul>
      </div>
    )
  }
});
