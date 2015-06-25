/** @jsx React.DOM */
var Route = ReactRouter.Route,
    DefaultRoute = ReactRouter.DefaultRoute;

this.DDSRoutes = (
  <Route handler={App}>
    <DefaultRoute handler={Home} />
    <Route handler={Login} path='login' />
  </Route>
);
