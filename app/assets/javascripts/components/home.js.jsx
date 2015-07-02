var Home = React.createClass({
  render: function() {
    var Child = this.props.isLoggedIn ? ProjectDashboard : SplashPage;
    return (
      <Child {...this.props} />
    )
  }
});
