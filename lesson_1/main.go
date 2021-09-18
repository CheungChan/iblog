package main

import "fmt"

const version = "0.0.1"

var name = "唐国强"

func main() {
	fmt.Println("当前程序版本是:" + version)
	fmt.Println("我是演员：" + name)
	name = "诸葛亮"
	fmt.Println("我在扮演:" + name)
}