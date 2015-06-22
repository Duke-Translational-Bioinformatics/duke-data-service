var App = React.createClass({
  render: function() {
    return (
      <div>
        <h1>App {this.props.foo}</h1>
        <ReactRouter.RouteHandler/>
      </div>
    )
  }
});
