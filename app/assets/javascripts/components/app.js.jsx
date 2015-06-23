/** @jsx React.DOM */
var RouteHandler = ReactRouter.RouteHandler,
    Link = ReactRouter.Link;

var App = React.createClass({
  render: function() {
    return (
      <div>
        <nav>
          <ul>
            <li>
              <Link to='/'>Home</Link>
            </li>
            <li>
              <Link to='/splash'>Splash Page</Link>
            </li>
          </ul>
        </nav>
        <h1>App {this.props.foo}</h1>
        <RouteHandler />
      </div>
    )
  }
});
