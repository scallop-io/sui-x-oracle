module pyth_rule::rule {

  use std::vector;
  use sui::coin::Coin;
  use sui::sui::SUI;
  use sui::clock::Clock;

  use pyth::pyth;
  use pyth::price;
  use pyth::i64;
  use pyth::state::{State as PythState};
  use pyth::price_info::{PriceInfoObject};
  use pyth::hot_potato_vector;
  use wormhole::state::{State as WormholeState};
  use wormhole::vaa;

  use x_oracle::x_oracle::{ Self, XOraclePriceUpdateRequest };
  use x_oracle::price_feed;

  const U8_MAX: u64 = 255;

  const PYTH_PRICE_DECIMALS_TOO_LARGE: u64 = 0;

  struct Rule has drop {}

  public fun get_pyth_price(
    wormhole_state: &WormholeState,
    pyth_state: &PythState,
    pyth_price_info_object: &mut PriceInfoObject,
    pyth_update_fee: Coin<SUI>,
    vaa_buf: vector<u8>,
    clock: &Clock,
  ): (u64, u64, u8, u64) {
    let vaa = vaa::parse_and_verify(wormhole_state, vaa_buf, clock);
    let vaa_vec = vector::singleton(vaa);
    let pyth_price_hot_potato = pyth::create_price_infos_hot_potato(pyth_state, vaa_vec, clock);
    let pyth_price_hot_potato = pyth::update_single_price_feed(
      pyth_state,
      pyth_price_hot_potato,
      pyth_price_info_object,
      pyth_update_fee,
      clock
    );
    hot_potato_vector::destroy(pyth_price_hot_potato);
    let pyth_price = pyth::get_price(pyth_state, pyth_price_info_object, clock);
    let price_updated_time  = price::get_timestamp(&pyth_price);
    let price_value = price::get_price(&pyth_price);
    let price_value = i64::get_magnitude_if_positive(&price_value);
    let price_conf = price::get_conf(&pyth_price);
    let price_decimals = price::get_expo(&pyth_price);
    let price_decimals = i64::get_magnitude_if_positive(&price_decimals);
    // For price value, the decimals could definitely fit in a u8, otherwise there's a bug
    assert!(price_decimals <= U8_MAX, PYTH_PRICE_DECIMALS_TOO_LARGE);
    let price_decimals = (price_decimals as u8);
    (price_value, price_conf, price_decimals, price_updated_time)
  }

  public fun set_price<T>(
    request: &mut XOraclePriceUpdateRequest<T>,
    pyth_state: &PythState,
    price: u64,
    last_updated: u64,
  ) {
    let price_feed = price_feed::new(price, last_updated);
    pyth::get_stale_price_threshold_secs(pyth_state);
    x_oracle::set_secondary_price(Rule {}, request, price_feed);
  }
}
