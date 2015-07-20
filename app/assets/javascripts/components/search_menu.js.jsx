var SearchMenu = React.createClass({
  render: function() {
    return (
      <form>
        <div className="form-group">
          <input type="text"
            onChange={this.props.handleSearchChange}
            className="form-control"
            placeholder="Search" />
        </div>
      </form>
    )
  }
});
