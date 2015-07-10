import React from 'react';
var mui = require('material-ui'),
    Slider = mui.Slider,
    FloatingActionButton = mui.FloatingActionButton;

class ItemList extends React.Component {

    constructor() {
        super();
    }

    onSliderChange(e, value) {
        console.log(value);
    }

    render() {
        var items = this.props.items.map(item => <li key={ item }>{ item }</li>),
            loading = this.props.loading ? <div className="loading-label">Loading...</div> : '';

        return (
            <div>
        { loading }
                <ul>
          { items }
                </ul>
                <Slider name="slider2" min={1} max={250} onChange={this.onSliderChange} defaultValue={0.5} />
                <FloatingActionButton iconClassName="muidocs-icon-action-grade" />
            </div>
        );
    }

}

ItemList.propTypes = {
    loading: React.PropTypes.bool,
    items: React.PropTypes.array
};

export default ItemList;