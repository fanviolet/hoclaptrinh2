extends RefCounted

# Offline seed records, explicitly labelled as sample data in the UI.
const NAMES = ["SkyBuilder","Linh Mây","CloudFox","Minh Anh","TowerBee","An Nhiên","BlueKitten","Hải Đăng","Mochi","Bảo Ngọc","SunnyStack","Tuấn Kiệt","Mèo Cam","Gia Hân","Bamboo","Hoàng Nam","StarPanda","Khánh Vy","MoonCat","Đức Anh","Minty","Ngọc Mai","PixelBird","Thanh Tùng","Kiki","Phương Linh","TinyCloud","Quang Huy","Luna","Thảo Nhi","Peachy","Anh Khoa","Maple","Diệu Anh","JellyBean","Nhật Minh","Choco","Hà My","Bumble","Thiên An","Coco","Trọng Phúc","Nova","Yến Nhi","Poppy","Minh Khôi","Kiwi","Bảo An","Pudding","SeaSalt"]

static func top50(player_height: float) -> Array:
	var rows: Array = []
	for i in range(50):
		rows.append({"id":"sample_%02d" % i,"name":NAMES[i],"height":snappedf(182.5-i*3.17,0.01),"sample":true})
	if is_finite(player_height) and player_height > 0:
		rows.append({"id":"you","name":"YOU","height":snappedf(player_height,0.01),"sample":false})
	rows.sort_custom(func(a,b):
		if is_equal_approx(a.height,b.height): return a.id < b.id
		return a.height > b.height)
	rows.resize(50)
	return rows
