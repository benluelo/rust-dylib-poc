#![feature(lazy_cell)]

use std::{ffi::CString, sync::LazyLock};

use async_ffi::async_ffi;

// #[cfg_attr(target_os = "linux", link_section = ".init_array")]
// #[used]
// pub static INITIALIZE: extern "C" fn() = {
#[ctor::ctor]
fn init() {
    tracing_subscriber::fmt::init();
}

//     init
// };

static RUNTIME: LazyLock<tokio::runtime::Runtime> = LazyLock::new(|| {
    println!("initializing reactor");

    tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .unwrap()
});

#[async_ffi]
#[no_mangle]
pub async extern "C" fn add(left: usize, right: usize) -> *mut u8 {
    RUNTIME
        .handle()
        .spawn(async {
            CString::new(
                reqwest::get("https://rpc.testnet.bonlulu.uno/abci_info")
                    .await
                    .unwrap()
                    .text()
                    .await
                    .unwrap(),
            )
            .unwrap()
        })
        .await
        .unwrap()
        .into_raw()
}
