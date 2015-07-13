/** @jsx React.DOM */
var Route = ReactRouter.Route,
    DefaultRoute = ReactRouter.DefaultRoute;

this.DDSRoutes = (
  <Route handler={App}>
    <DefaultRoute name='home' handler={Home} />
    <Route name='login' handler={Login} path='login' />
    <Route name="project_detail" handler={ProjectDetail} path="/projects/:id" />
    <Route name="project_folders" handler={ProjectFolders} path="/projects/:id/folders" />
    <Route name="project_members" handler={ProjectMembers} path="/projects/:id/members" />
  </Route>
);
