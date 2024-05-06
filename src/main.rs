use std::{ffi::CString, path::PathBuf};

use async_ffi::FfiFuture;
use libloading::{Library, Symbol};
use tokio::task::LocalSet;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let path = PathBuf::from(std::env::args_os().nth(1).unwrap());
    assert!(path.exists());

    unsafe {
        let lib = Library::new(path).unwrap();
        let add: Symbol<unsafe extern "C" fn(left: usize, right: usize) -> FfiFuture<*mut u8>> =
            lib.get(b"add").unwrap();

        let set = LocalSet::new();

        for i in 0..10 {
            set.spawn_local(async move {
                tracing::info!(%i);
            });
            set.spawn_local(add(1, 2));
        }

        set.await;

        println!(
            "{}",
            String::from_utf8(CString::from_raw(add(1, 2).await).into_bytes()).unwrap()
        );
    };
}
