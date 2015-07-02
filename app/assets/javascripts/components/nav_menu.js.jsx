var Link = ReactRouter.Link;

var NavMenu = React.createClass({

  render: function() {
    var Child = this.props.isLoggedIn ? LogoutMenu : LoginMenu;
    return (
      <div className="navbar navbar-default navbar-fixed-top" role="navigation">
       <div className="navbar-header">
        <button type="button" className="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
          <span className="sr-only">Toggle navigation</span>
          <span className="icon-bar"></span>
          <span className="icon-bar"></span>
          <span className="icon-bar"></span>
        </button>
        <a href="/" title="Home"><p>Todo Logo</p><i className="fa fa-home fa-lg">Duke Data Services</i></a>
       </div>
       <Child {...this.props} />
      </div>
    )
  }
});

var LogoutMenu = React.createClass({

  render: function() {
    return (
      <div className="navbar-collapse collapse">
        <ul className="nav navbar-nav navbar-right">
         <li className="dropdown">
           <a className="dropdown-toggle" data-toggle="dropdown">
             <i className='fa fa-user'></i>{this.props.currentUser.display_name}
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
    )
  }
});

var LoginMenu = React.createClass({

  render: function() {
    return (
        <div>
          <ul className="nav navbar-nav navbar-right">
            <li className="dropdown">
              <Link to="login">Login</Link>
           </li>
          </ul>
        </div>
    )
  }
});
