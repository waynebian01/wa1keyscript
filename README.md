# Wa1Keyscript

基于Wa1Key编写的自定义脚本脚本。

Wa1Key使用方法请参考 [Wa1Key项目](https://github.com/wa1key/wa1key)。

Wa1Key文件夹内容适用于Wa1Key程序，其他文件需写入WeakAura2插件内。

## 使用方法(首次使用):
1. 将Skippy.wa1key放入Wa1Key目录\module
2. 启动游戏
3. 启动Wa1Key
4. 选择将Skippy模块
5. 进入游戏
6. 打开WA插件,导入字符串
7. 重载 /reload ui
8. 如果还不行，重复以上步骤

## 支持的治疗: 
### 正式服
*正式服需要指定天赋才能使用*
* 队伍: *无*
* 团队: 
    * 神牧:
    ```
    CEQAAAAAAAAAAAAAAAAAAAAAAwAAAAAAAgxYmZbmZGzYwMzM2mhZAAAAwsYZ2G2mZGMLMmxMjBLLwMmaWAYmFsQYMLDoxCswiZZAA
    ```

    * 奶德:
    ```
    CkGAAAAAAAAAAAAAAAAAAAAAAsNmZGLbjZmxiZb4BYstNzyitZAAAAAAAAAAAAsZoZjx0MDwsMzyMzwwMAAAAAgBAMAAQAAAz2MbNLzsZjxMDwshRD
    ```
    
### 熊猫人
* 队伍: *神牧*, *奶骑*, *奶德*, *奶萨*，*奶僧*
* 团队: *奶骑*

### 泰坦重铸
* 队伍：*奶骑*, *戒律*
* 团队：*无*

## 其他说明:
* 熊猫人
    * 奶骑
        * 需要手动给一个目标上[圣光道标](https://www.wowhead.com/mop-classic/cn/spell=53563).
    * 奶德
        * 默认给T续[生命绽放](https://www.wowhead.com/mop-classic/cn/spell=33763),
可以选中任意队友释放,会自动对有[生命绽放](https://www.wowhead.com/mop-classic/cn/spell=33763)
的单位释放[生命绽放](https://www.wowhead.com/mop-classic/cn/spell=33763).
        * 因无法监控[野性蘑菇](https://www.wowhead.com/mop-classic/cn/spell=145205)
,需要自己手动施放或引爆.

* 泰坦重铸
    * 奶骑
        * 需要点出天赋[圣光道标]才能运行，如果需要从10级运行，需要在wa里的载入修改
        


