##玩家数据（实时 和 结算）
extends Node

var player_name: String##玩家
var combo: int##连击数
var score: int##分数，满分为一百万
var aac: float##（百分比）准度
var max_combo: int##最大连击数

var perfect: int##perfect表现的打击数
var good: int##good表现的打击数
var bad: int##bad表现的打击数
var miss: int##miss表现的打击数
var hit_count: int##总打击数

var grade##评级
enum Grade {##枚举评级
	GOLD_NYA,##AP
	PINK_NYA,##FC
	GREEN_NYA,##达到95 0000
	BLUE_NYA,##达到90 0000
	PURPLE_NYA,##达到85 0000
	WHITE_NYA##未达到85 0000（包括未评级）
}
