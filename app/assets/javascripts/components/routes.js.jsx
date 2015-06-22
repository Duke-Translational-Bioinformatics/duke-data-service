var Route = ReactRouter.Route;
this.DDSRoutes = (
  <Route handler={App} path='/'>
    <Route name='splash' handler={Splash} path='splash' />
  </Route>
);
