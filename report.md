#課題4 ルータのCLIを作ろう
##課題内容
ルータのコマンドラインインタフェース (CLI) を作ろう。

次の操作ができるコマンドを作ろう。

* ルーティングテーブルの表示
* ルーティングテーブルエントリの追加と削除
* ルータのインタフェース一覧の表示
* そのほか、あると便利な機能

コントローラを操作するコマンドの作りかたは、第3回パッチパネルで作った patch_panel コマンドを参考にしてください。

##解答
まず，新たにコントローラを操作するコマンドsimple\_router追加するために./bin/simple\_routerファイルを新たに作成した．第3回パッチパネルのpatch_panelコマンドのファイルを参考にし，各サブコマンドの部分を変更した．
###1.ルーティングテーブルの表示

ルーティングテーブルの表示のサブコマンドはshow\_routing\_tableとした．引数はない．このコマンドはSimpleRouterクラスのshow\_routing\_tableメソッドを呼び出している．show\_routing\_tableメソッドはルーティングテーブル一覧を文字列にして返すので戻り値を標準出力に表示している．

```
#bin/simple_touter
  desc 'Show routing table'
  arg_name ''
  command :show_routing_table do |c|
    c.desc 'Location to find socket files'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR

    c.action do |_global_options, options, args|
      ret = Trema.trema_process('SimpleRouter', options[:socket_dir]).controller.
        show_routing_table()
      puts(ret)
    end
  end
```

lib/simple\_router.rbにはSimpleRouterクラスが定義されている．
サブコマンドから呼び出されるshow\_routing\_table()は以下の通りである．ルーティングテーブルはインスタンス変数@routing\_tableに保存されている．@routing\_tableはRoutingTableクラスのインスタンスであるので，RoutingTableクラスにルーティングテーブルの一覧を文字列にして返却するメソッドを追加し，その結果をそのまま返すようにする．

```
#lib/sinple_router.rb
	def show_routing_table()
	    return   @routing_table.show()
	end
```

RoutingTableクラスに上記のルーティングテーブルの一覧を文字列にして返却するメソッドを追加した．それぞれのルーティングテーブルエントリは@dbに保存されているのでipアドレス，ネットマスク，ホップ先を読み出し，表示するように整形して文字列として書き出す．全てのエントリにアクセスしたら文字列を返す．

```
#lib/routing_table.rb
  def show()
    str = "destination/netmask   next_hop\n"
    @db.each_with_index do |each, i|
      each.each do |key, value|
        str += sprintf("%-22s%s\n",IPv4Address.new(key).to_s + "/" + i.to_s, value)
      end
    end
    return str
  end
```

###2.ルーティングテーブルエントリの追加
ルーティングテーブルエントリ追加のサブコマンドはaddとした．引数は宛先，ネットマスク，ホップ先である．このサブコマンドはSimpleRouterクラスのadd\_routing\_tabel\_entryメソッドを呼び出している．このメソッドは宛先，ネットマスク，ホップ先を引数に取るので渡している．

```
#/bin/simple_router
  desc 'Add routing table entry'
  arg_name 'destination netmask_length next_hop'
  command :add do |c|
    c.desc 'Location to find socket files'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR

    c.action do |_global_options, options, args|
      destination = args[0]
      netmask_length = args[1].to_i
      next_hop = args[2]
      Trema.trema_process('SimpleRouter', options[:socket_dir]).controller.
        add_routing_tabel_entry(destination,netmask_length,next_hop)
    end
  end
```

SimpleRouterクラスのadd\_routing\_tabel\_entryメソッドは@routing\_tableのエントリを追加するメソッドaddを呼び出している．

```
#lib/simple_router.rb
  def add_routing_tabel_entry(dest,netmask,next_hop)
    @routing_table.add({:destination=>dest,:netmask_length=>netmask,:next_hop=>next_hop})
  end
```
###3.ルーティングテーブルエントリの削除
ルーティングテーブルエントリ削除のサブコマンドはdeleteとした．引数は宛先，ネットマスクである．このサブコマンドはSimpleRouterクラスのdelete\_routing\_tabel\_entryメソッドを呼び出している．このメソッドは宛先，ネットマスクを引数に取るので渡している．

```
  desc 'delete outing table entry'
  arg_name 'destination netmask_length'
  command :delete do |c|
    c.desc 'Location to find socket files'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR

    c.action do |_global_options, options, args|
      destination = args[0]
      netmask_length = args[1].to_i
      Trema.trema_process('SimpleRouter', options[:socket_dir]).controller.
        delete_routing_tabel_entry(destination,netmask_length)
    end
  end
```

SimpleRouterクラスのdelete\_routing\_tabel\_entryメソッドは@routing\_tableのエントリを削除するメソッドdeleteを呼び出している．

```
#lib/simple_router.rb
  def delete_routing_tabel_entry(dest,netmask)
    @routing_table.delete({:destination=>dest,:netmask_length=>netmask})
  end
```

RoutingTableクラスに上記のルーティングテーブルエントリを削除するメソッドを追加した．@dbから引数で与えられた宛先アドレスとネットマスクに一致するエントリを削除している．


```
#lin/routing_table.rb
  def delete(options)
    netmask_length = options.fetch(:netmask_length)
    prefix = IPv4Address.new(options.fetch(:destination)).mask(netmask_length)
    @db[netmask_length].delete(prefix.to_i)
  end
```
###4.ルータのインタフェース一覧の表示

ルーティングテーブルの表示のサブコマンドはshow\_interfacesとした．引数はない．このコマンドはSimpleRouterクラスのshow\_interfacesメソッドを呼び出している．show\_interfacesメソッドはインターフェース一覧を文字列にして返すので戻り値を標準出力に表示している．

```
#bin/simple_router
  desc 'Show interfaces'
  arg_name ''
  command :show_interfaces do |c|
    c.desc 'Location to find socket files'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR

    c.action do |_global_options, options, args|
      ret = Trema.trema_process('SimpleRouter', options[:socket_dir]).controller.
        show_interface()
      puts(ret)
    end
  end
```

サブコマンドから呼び出されるメソッドshow\_interfaces()は以下の通りである．ルーティングテーブルはインスタンス変数@interfacesに保存されている．@routing\_tableはRoutingTableクラスのインスタンスなので，Interfacesクラスにインターフェースの一覧を文字列にして返却するメソッドを追加し，その結果をそのまま返すようにする．

```
#lib/simple_router.rb
  def show_interface()
    return @interfaces.show()
  end
```
Interfacesクラスに上記のメソッドを追加した．インターフェースは@listに保存されているのでポート，macアドレス，ipアドレス，ネットマスクを読み出し，表示するように整形して文字列として書き出す．全てのエントリにアクセスしたら文字列を返す．

```
#lib/interfaces.rb
  def show()
    str = sprintf("%-5s %-20s %-15s %-10s\n", "port", "mac_address", "ip_address", "netmask")
    @list.each do |each|
      str += sprintf("%-5s %-20s %-15s %-10s\n", each.port_number, each.mac_address, each.ip_address.to_s, each.netmask_length)
    end
    return str
  end
```
###動作確認
以下の手順で動作確認を行った．

1. ルーティングテーブルの表示
1. ルーティングテーブルエントリの追加
1. ルーティングテーブルの表示
1. ルーティングテーブルの削除
1. ルーティングテーブルの表示
1. ルータのインタフェース一覧の表示

初期状態として読み込むインターフェースとルーティングテーブルの設定は以下のとおりである．

```
# Simple router configuration
module Configuration
  INTERFACES = [
    {
      port: 1,
      mac_address: '00:00:00:01:00:01',
      ip_address: '192.168.1.1',
      netmask_length: 24
    },
    {
      port: 2,
      mac_address: '00:00:00:01:00:02',
      ip_address: '192.168.2.1',
      netmask_length: 24
    }
  ]

  ROUTES = [
    {
      destination: '0.0.0.0',
      netmask_length: 0,
      next_hop: '192.168.1.2'
    }
  ]
end

```

以下に実行結果を示す．

```
$ ./bin/simple_router show_routing_table
destination/netmask   next_hop
0.0.0.0/0             192.168.1.2

$ ./bin/simple_router add 192.168.2.0 24 192.168.2.3

$ ./bin/simple_router show_routing_table
destination/netmask   next_hop
0.0.0.0/0             192.168.1.2
192.168.2.0/24        192.168.2.3

$ ./bin/simple_router delete 192.168.2.0 24

$ ./bin/simple_router show_routing_table
destination/netmask   next_hop
0.0.0.0/0             192.168.1.2

$ ./bin/simple_router show_interfaces
port  mac_address          ip_address      netmask   
1     00:00:00:01:00:01    192.168.1.1     24        
2     00:00:00:01:00:02    192.168.2.1     24 
```

このようにルーティングテーブルの表示，ルーティングテーブルエントリの追加と削除，インターフェース一覧の表示が実行できていることがわかる．
