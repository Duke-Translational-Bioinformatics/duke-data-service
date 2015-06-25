/** @jsx React.DOM */
var Route = ReactRouter.Route,
    DefaultRoute = ReactRouter.DefaultRoute;

this.DDSRoutes = (
  <Route handler={App}>
    <DefaultRoute name='home' handler={Home} />
    <Route name='login' handler={Login} path='login' />
  </Route>
);
