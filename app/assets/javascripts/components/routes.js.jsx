/** @jsx React.DOM */
var Route = ReactRouter.Route,
    DefaultRoute = ReactRouter.DefaultRoute;

this.DDSRoutes = (
  <Route handler={App}>
    <DefaultRoute handler={Home} />
    <Route handler={Splash} path='splash' />
  </Route>
);
