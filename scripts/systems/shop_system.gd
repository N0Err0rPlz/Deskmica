# shop_system.gd —— 商店系统：纯代码购买 API，Phase 2 不接 UI
extends Node


func _ready() -> void:
	print("[ShopSystem] Initialized.")


func try_buy_car(car_id: String) -> bool:
	var def: CarDefinition = DataRegistry.get_car(car_id)
	if def == null:
		return false
	if not EconomyManager.spend_credits(def.purchase_price):
		return false
	SignalBus.item_purchased.emit("car", car_id)
	SignalBus.car_purchased.emit(car_id)
	SignalBus.car_added_to_garage.emit(car_id)
	return true


func try_buy_kit(car_id: String, kit_id: String) -> bool:
	var def: KitDefinition = DataRegistry.get_kit(kit_id)
	if def == null:
		return false
	if not EconomyManager.spend_credits(def.purchase_price):
		return false
	SignalBus.item_purchased.emit("kit", kit_id)
	SignalBus.kit_purchased.emit(car_id, kit_id)
	return true
