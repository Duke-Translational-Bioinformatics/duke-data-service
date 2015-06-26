var Navigation = ReactRouter.Navigation;

var NavMenu = React.createClass({
  mixins: [ Navigation ],

  render: function() {
    var displayStyle = this.props.api_token ? {display: 'block'} : {display: 'none'};
    return (
      <div className="navbar navbar-default" role="navigation">
        <div className="container-fluid">
         <div className="navbar-header">
          <button type="button" className="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
            <span className="sr-only">Toggle navigation</span>
            <span className="icon-bar"></span>
            <span className="icon-bar"></span>
            <span className="icon-bar"></span>
          </button>
          <a href="/" title="Home"><p>Todo Logo</p><i className="fa fa-home fa-lg">Duke Data Services</i></a>
         </div>
         <div className="navbar-collapse collapse">
          <ul id="user-control-menu" style={displayStyle} className="nav navbar-nav navbar-right">
            <li className="dropdown">
              <a href="#" className="dropdown-toggle" data-toggle="dropdown">
                <i className='fa fa-user'></i>Darin London
                <b className="caret"></b>
              </a>
              <ul className="dropdown-menu">
                <li>
                  <a href='' onClick={this.props.handleLogout}>
                    <i className="fa fa-sign-out"></i>
                    Logout
                  </a>
                </li>
              </ul>
            </li>
          </ul>
         </div>
        </div>
      </div>
    )
  }
});
