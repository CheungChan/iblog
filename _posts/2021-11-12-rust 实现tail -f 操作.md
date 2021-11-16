---
Title: rust实现tail -f 
key: rust_tail
layout: article
date: '2021-11-12 16:50:00'
tags:  rust
typora-root-url: ../../iblog

---
网上有个例子，但是不支持指定-f参数，也就是最后算多少行开始。我做了下改动，给register函数添加了参数n

```rust
use std::fs::File;
use std::io;
use std::io::BufReader;
use std::io::ErrorKind;
use std::io::prelude::*;
use std::io::SeekFrom;
use std::os::unix::fs::MetadataExt;
use std::path::Path;
use std::thread::sleep;
use std::time::Duration;

pub enum LogWatcherAction {
    None,
    SeekToEnd,
}

pub struct LogWatcher {
    filename: String,
    inode: u64,
    pos: u64,
    reader: BufReader<File>,
    finish: bool,
}

impl LogWatcher {
    pub fn register<P: AsRef<Path>>(filename: P, n: u64) -> Result<LogWatcher, io::Error> {
        let f = match File::open(&filename) {
            Ok(x) => x,
            Err(err) => return Err(err),
        };

        let metadata = match f.metadata() {
            Ok(x) => x,
            Err(err) => return Err(err),
        };

        let mut reader = BufReader::new(f);
        let pos = if n == 0 {
            metadata.len()
        } else {
            // 后n行的长度
            let mut content: Vec<String> = vec![];
            let file = File::open(&filename)?;
            let reader = BufReader::new(file);

            for line in reader.lines() {
                if let Ok(l) = line {
                    content.push(l);
                }
            }
            let content = &content[content.len() - n as usize..];
            let s: String = content.clone().join("");
            println!("监听从最后{}行开始", n);
            metadata.len() - s.len() as u64
        };
        reader.seek(SeekFrom::Start(pos)).unwrap();
        Ok(LogWatcher {
            filename: filename.as_ref().to_string_lossy().to_string(),
            inode: metadata.ino(),
            pos: pos,
            reader: reader,
            finish: false,
        })
    }

    fn reopen_if_log_rotated<F: ?Sized>(&mut self, callback: &mut F)
        where
            F: FnMut(String) -> LogWatcherAction,
    {
        loop {
            match File::open(&self.filename) {
                Ok(x) => {
                    let f = x;
                    let metadata = match f.metadata() {
                        Ok(m) => m,
                        Err(_) => {
                            sleep(Duration::new(1, 0));
                            continue;
                        }
                    };
                    if metadata.ino() != self.inode {
                        self.finish = true;
                        self.watch(callback);
                        self.finish = false;
                        println!("reloading log file");
                        self.reader = BufReader::new(f);
                        self.pos = 0;
                        self.inode = metadata.ino();
                    } else {
                        sleep(Duration::new(1, 0));
                    }
                    break;
                }
                Err(err) => {
                    if err.kind() == ErrorKind::NotFound {
                        sleep(Duration::new(1, 0));
                        continue;
                    }
                }
            };
        }
    }

    pub fn watch<F: ?Sized>(&mut self, callback: &mut F)
        where
            F: FnMut(String) -> LogWatcherAction,
    {
        loop {
            let mut line = String::new();
            let resp = self.reader.read_line(&mut line);
            match resp {
                Ok(len) => {
                    if len > 0 {
                        self.pos += len as u64;
                        self.reader.seek(SeekFrom::Start(self.pos)).unwrap();
                        match callback(line.replace("\n", "")) {
                            LogWatcherAction::SeekToEnd => {
                                println!("SeekToEnd");
                                self.reader.seek(SeekFrom::End(0)).unwrap();
                            }
                            LogWatcherAction::None => {}
                        }
                        line.clear();
                    } else {
                        if self.finish {
                            break;
                        } else {
                            self.reopen_if_log_rotated(callback);
                            self.reader.seek(SeekFrom::Start(self.pos)).unwrap();
                        }
                    }
                }
                Err(err) => {
                    println!("{}", err);
                }
            }
        }
    }
}

```

