var Link = ReactRouter.Link;

var NavMenu = React.createClass({

  render: function() {
    var Child = this.props.isLoggedIn ? LogoutMenu : LoginMenu;
    return (
      <div className="navbar navbar-default navbar-fixed-top NavMenu" role="navigation">
       <ul className="nav navbar-nav navbar-left">
         <MainMenu menuItems={this.props.menuItems} />
         <form className="navbar-form navbar-left">
           <div className="form-group">
             <input type="text" className="form-control" placeholder="Search" />
           </div>
         </form>
       </ul>
       <ul className="nav navbar-nav navbar-right">
         <li>
           <Child {...this.props} />
         </li>
       </ul>
      </div>
    )
  }
});

var LogoutMenu = React.createClass({

  render: function() {
    return (
      <div className="navbar-collapse collapse NavMenu">
        <ul className="nav navbar-nav">
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
      <Link to="login">Login</Link>
    )
  }
});
