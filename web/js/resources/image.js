/*
* Licensed to the Apache Software Foundation (ASF) under one or more
* contributor license agreements.  See the NOTICE file distributed with
* this work for additional information regarding copyright ownership.
* The ASF licenses this file to You under the Apache License, Version 2.0
* (the "License"); you may not use this file except in compliance with
* the License.  You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

function Image() {
	Resource.apply(this, Array.prototype.slice.call(arguments));
	this.selids = [];
	this.selectingall = false;
	this.restype = 'image';
}
Image.prototype = new Resource();

Image.prototype.colformatter = function(value, rowIndex, obj) {
	if(obj.field == 'deleted' ||
	   obj.field == 'test' ||
	   obj.field == 'forcheckout' ||
	   obj.field == 'checkuser' ||
	   obj.field == 'rootaccess') {
		if(value == "0")
			return '<span class="rederrormsg">false</span>';
		if(value == "1")
			return '<span class="ready">true</span>';
	}
	return value;
}

var resource = new Image();

function inlineEditResourceCB(data, ioArgs) {
	if(data.items.status == 'success') {
		if(dijit.byId('advancedoptions').open)
			dijit.byId('advancedoptions').toggle();
		dojo.byId('saveresourcecont').value = data.items.cont;
		dijit.byId('addeditdlg').set('title', data.items.title);
		dijit.byId('addeditbtn').set('label', 'Save Changes');
		dojo.byId('editresid').value = data.items.resid;
		dijit.byId('name').set('value', data.items.data.prettyname);
		dijit.byId('owner').set('value', data.items.data.owner);
		dijit.byId('description').set('value', data.items.data.description);
		dijit.byId('usage').set('value', data.items.data.usage);
		dijit.byId('ram').set('value', data.items.data.minram);
		dijit.byId('cores').set('value', data.items.data.minprocnumber);
		dijit.byId('cpuspeed').set('value', data.items.data.minprocspeed);
		dijit.byId('networkspeed').set('value', data.items.data.minnetwork);
		dijit.byId('concurrent').set('value', data.items.data.maxconcurrent);
		dijit.byId('reload').set('value', data.items.data.reloadtime);
		dijit.byId('checkout').set('value', data.items.data.forcheckout);
		dijit.byId('checkuser').set('value', data.items.data.checkuser);
		dijit.byId('rootaccess').set('value', data.items.data.rootaccess);
		dojo.byId('connectmethodlist').innerHTML = data.items.data.connectmethods.join('<br>');
		dijit.byId('connectmethodttd').set('href', data.items.data.connectmethodurl);
		dijit.byId('subimagedlg').set('href', data.items.data.subimageurl);
		dojo.byId('revisiondiv').innerHTML = data.items.data.revisionHTML;
		AJdojoCreate('revisiondiv');
		dijit.byId('addeditdlg').show();
	}
	else if(data.items.status == 'noaccess') {
		alert('Access denied to edit this item');
	}
}

function delayedEditResize() {
	setTimeout(function() {resizeRecenterDijitDialog('addeditdlg');}, 300);
}

function resetEditResource() {
	dijit.byId('name').reset();
	dijit.byId('owner').reset();
	dijit.byId('description').reset();
	dijit.byId('usage').reset();
	dijit.byId('imgcomments').reset();
	dijit.byId('ram').reset();
	dijit.byId('cores').reset();
	dijit.byId('cpuspeed').reset();
	dijit.byId('networkspeed').reset();
	dijit.byId('concurrent').reset();
	if(dijit.byId('reload'))
		dijit.byId('reload').reset();
	dijit.byId('checkout').reset();
	dijit.byId('checkuser').reset();
	dijit.byId('rootaccess').reset();
	if(dijit.byId('sysprep'))
		dijit.byId('sysprep').reset();
	if(dojo.byId('connectmethodids'))
		dojo.byId('connectmethodids').value = '';
	dojo.byId('addeditdlgerrmsg').innerHTML = '';
	if(dijit.byId('advancedoptions').open)
		dijit.byId('advancedoptions').toggle();
	dojo.byId('connectmethodlist').innerHTML = '';
}

function saveResource() {
	var submitbtn = dijit.byId('addeditbtn');
	var errobj = dojo.byId('addeditdlgerrmsg');
	if(! checkValidatedObj('name', errobj))
		return;
	/*if(! dijit.byId('owner')._hasBeenBlurred && dijit.byId('owner').get('value') == '') {
		dijit.byId('owner')._hasBeenBlurred = true;
		dijit.byId('owner').validate();
		submitbtn.set('disabled', true);
		setTimeout(function() {
			saveResource();
			submitbtn.set('disabled', false);
		}, 1000);
		return;
	}*/
	if(ownerchecking) {
		submitbtn.set('disabled', true);
		setTimeout(function() {
			saveResource();
			submitbtn.set('disabled', false);
		}, 1000);
		return;
	}
	if(! checkValidatedObj('owner', errobj))
		return;
	if(! checkValidatedObj('ram', errobj))
		return;
	if(! checkValidatedObj('cores', errobj))
		return;
	if(! checkValidatedObj('cpuspeed', errobj))
		return;
	if(! checkValidatedObj('concurrent', errobj))
		return;
	if(! checkValidatedObj('reload', errobj))
		return;

	if(dojo.byId('editresid').value == 0)
		var data = {continuation: dojo.byId('addresourcecont').value};
	else
		var data = {continuation: dojo.byId('saveresourcecont').value};

	data['name'] = dijit.byId('name').get('value');
	data['owner'] = dijit.byId('owner').get('value');

	data['networkspeed'] = parseInt(dijit.byId('networkspeed').get('value'));
	if((+log10(data['networkspeed']).toFixed(2) % 1) != 0) { // log10(1000) -> 2.9999999999999996
		errobj.innerHTML = 'Invalid network speed specified';
		return;
	}
	data['concurrent'] = dijit.byId('concurrent').get('value');
	if(data['concurrent'] < 0 || data['concurrent'] == 1 || data['concurrent'] > 255) {
		errobj.innerHTML = 'Max Concurrent Usage must be 0 or from 2 to 255';
		return;
	}
	data['checkout'] = parseInt(dijit.byId('checkout').get('value'));
	if(data['checkout'] != 0 && data['checkout'] != 1) {
		errobj.innerHTML = 'Invalid value specified for \'Available for checkout\'';
		return;
	}
	data['checkuser'] = parseInt(dijit.byId('checkuser').get('value'));
	if(data['checkuser'] != 0 && data['checkuser'] != 1) {
		errobj.innerHTML = 'Invalid value specified for \'Check for logged in user\'';
		return;
	}
	data['rootaccess'] = parseInt(dijit.byId('rootaccess').get('value'));
	if(data['rootaccess'] != 0 && data['rootaccess'] != 1) {
		errobj.innerHTML = 'Invalid value specified for \'Users have administrative access\'';
		return;
	}
	if(dijit.byId('sysprep')) {
		data['sysprep'] = parseInt(dijit.byId('sysprep').get('value'));
		if(data['sysprep'] != 0 && data['sysprep'] != 1) {
			errobj.innerHTML = 'Invalid value specified for \'Use sysprep\'';
			return;
		}
		if(! /[0-9,]+/.test(dojo.byId('connectmethodids').value)) {
			errobj.innerHTML = 'Invalid Connect Methods specified';
			return;
		}
		data['connectmethodids'] = dojo.byId('connectmethodids').value;
	}

	data['desc'] = dijit.byId('description').get('value');
	data['usage'] = dijit.byId('usage').get('value');
	if(dijit.byId('imgcomments'))
		data['imgcomments'] = dijit.byId('imgcomments').get('value');
	data['ram'] = dijit.byId('ram').get('value');
	data['cores'] = dijit.byId('cores').get('value');
	data['cpuspeed'] = dijit.byId('cpuspeed').get('value');
	if(dijit.byId('reload'))
		data['reload'] = dijit.byId('reload').get('value');

	submitbtn.set('disabled', true);
	RPCwrapper(data, saveResourceCB, 1);
}

function submitClickThrough() {
	var submitbtn = dijit.byId('clickthroughDlgBtn');
	var data = {continuation: dojo.byId('addresourcecont').value};
	submitbtn.set('disabled', true);
	RPCwrapper(data, saveResourceCB, 1);
}

function saveResourceCB(data, ioArgs) {
	if(data.items.status == 'error') {
		dojo.byId('addeditdlgerrmsg').innerHTML = '<br>' + data.items.msg;
		dijit.byId('addeditbtn').set('disabled', false);
		return;
	}
	else if(data.items.status == 'adderror') {
		alert(data.items.errormsg);
		dijit.byId('clickthroughdlg').hide();
	}
	else if(data.items.status == 'success') {
		if(data.items.action == 'clickthrough') {
			dojo.byId('addresourcecont').value = data.items.cont;
			dojo.byId('clickthroughDlgContent').innerHTML = data.items.agree;
			dijit.byId('addeditbtn').set('disabled', false);
			dijit.byId('clickthroughdlg').show();
			return;
		}
		else if(data.items.action == 'add') {
			dijit.byId('clickthroughdlg').hide();
			resRefresh();
		}
		else {
			resourcegrid.store.fetch({
				query: {id: data.items.data.id},
				onItem: function(item) {
					resourcegrid.store.setValue(item, 'name', data.items.data.prettyname);
					resourcegrid.store.setValue(item, 'owner', data.items.data.owner);
					resourcegrid.store.setValue(item, 'minram', data.items.data.minram);
					resourcegrid.store.setValue(item, 'minprocnumber', data.items.data.minprocnumber);
					resourcegrid.store.setValue(item, 'minprocspeed', data.items.data.minprocspeed);
					resourcegrid.store.setValue(item, 'minnetwork', data.items.data.minnetwork);
					resourcegrid.store.setValue(item, 'maxconcurrent', parseInt(data.items.data.maxconcurrent));
					resourcegrid.store.setValue(item, 'forcheckout', data.items.data.forcheckout);
					resourcegrid.store.setValue(item, 'checkuser', data.items.data.checkuser);
					resourcegrid.store.setValue(item, 'rootaccess', parseInt(data.items.data.rootaccess));
					resourcegrid.store.setValue(item, 'reloadtime', data.items.data.reloadtime);
				},
				onComplete: function(items, result) {
					// when call resourcegrid.sort directly, the table contents disappear; not sure why
					setTimeout(function() {resourcegrid.sort();}, 10);
				}
			});
		}
		dijit.byId('name').reset();
		dijit.byId('owner').reset();
		dijit.byId('networkspeed').reset();
		dijit.byId('concurrent').reset();
		dijit.byId('checkout').reset();
		dijit.byId('checkuser').reset();
		dijit.byId('rootaccess').reset();
		dijit.byId('description').reset();
		dijit.byId('usage').reset();
		if(dijit.byId('imgcomments')) {
			dijit.byId('imgcomments').reset();
		}
		dijit.byId('ram').reset();
		dijit.byId('cores').reset();
		dijit.byId('cpuspeed').reset();
		if(dijit.byId('reload'))
			dijit.byId('reload').reset();
		dijit.byId('addeditdlg').hide();
		dojo.byId('addeditdlgerrmsg').innerHTML = '';
		dijit.registry.filter(function(widget, index){return widget.id.match(/^comments/);}).forEach(function(widget) {widget.destroy();});
		setTimeout(function() {dijit.byId('addeditbtn').set('disabled', false);}, 250);
	}
}

function updateCurrentConMethods() {
	var tmp = dijit.byId('addcmsel').get('value');
	if(tmp == '') {
		dijit.byId('addcmsel').set('disabled', true);
		dijit.byId('addcmbtn').set('disabled', true);
	}
	else {
		dijit.byId('addcmsel').set('disabled', false);
		dijit.byId('addcmbtn').set('disabled', false);
	}
	// update list of current methods
	var obj = dojo.byId('curmethodsel');
	for(var i = obj.options.length - 1; i >= 0; i--)
		obj.remove(i);
	cmstore.fetch({
		query: {active: 1},
		onItem: function(item) {
			var obj = dojo.byId('curmethodsel').options;
			obj[obj.length] = new Option(item.display[0], item.name[0], false, false);
		},
		onComplete: function() {
			sortSelect(dojo.byId('curmethodsel'));
			updateConnectionMethodList();
		}
	});
}

function addSubimage() {
	dijit.byId('addbtn').attr('label', 'Working...');
	var data = {continuation: dojo.byId('addsubimagecont').value,
	            imageid: dijit.byId('addsubimagesel').value};
	RPCwrapper(data, addSubimageCB, 1);
}

function addSubimageCB(data, ioArgs) {
	if(data.items.error) {
		dijit.byId('addbtn').attr('label', 'Add Subimage');
		alert(data.items.msg);
		return;
	}
	var obj = dojo.byId('cursubimagesel');
	if(obj.options[0].text == '(None)') {
		obj.disabled = false;
		obj.remove(0);
	}
	dojo.byId('addsubimagecont').value = data.items.addcont;
	dojo.byId('remsubimagecont').value = data.items.remcont;
	var index = obj.options.length;
	obj.options[index] = new Option(data.items.name, data.items.newid, false, false);
	sortSelect(obj);
	dojo.byId('subimgcnt').innerHTML = obj.options.length;
	dijit.byId('addbtn').attr('label', 'Add Subimage');
}

function remSubimages() {
	var obj = dojo.byId('cursubimagesel');
	var imgids = new Array();
	for(var i = obj.options.length - 1; i >= 0; i--) {
		if(obj.options[i].selected)
			imgids.push(obj.options[i].value);
	}
	if(! imgids.length)
		return;
	var ids = imgids.join(',');
	dijit.byId('rembtn').attr('label', 'Working...');
	var data = {continuation: dojo.byId('remsubimagecont').value,
	            imageids: ids};
	RPCwrapper(data, remSubimagesCB, 1);
}

function remSubimagesCB(data, ioArgs) {
	if(data.items.error) {
		dijit.byId('rembtn').attr('label', 'Remove Selected Subimage(s)');
		alert(data.items.msg);
		return;
	}
	var obj = dojo.byId('cursubimagesel');
	for(var i = obj.options.length - 1; i >= 0; i--) {
		if(obj.options[i].selected)
			obj.remove(i);
	}
	if(! obj.options.length) {
		obj.disabled = true;
		obj.options[0] = new Option('(None)', 'none', false, false);
		dojo.byId('subimgcnt').innerHTML = 0;
	}
	else
		dojo.byId('subimgcnt').innerHTML = obj.options.length;
	dojo.byId('addsubimagecont').value = data.items.addcont;
	dojo.byId('remsubimagecont').value = data.items.remcont;
	dijit.byId('rembtn').attr('label', 'Remove Selected Subimage(s)');
}

function selectConMethodRevision(url) {
	var revid = dijit.byId('conmethodrevid').get('value');
	dijit.byId('addcmsel').set('disabled', true);
	dijit.byId('addcmbtn').set('disabled', true);
	var oldstore = cmstore;
	cmstore = new dojo.data.ItemFileWriteStore({url: url + '&revid=' + revid});
	dijit.byId('addcmsel').setStore(cmstore, '', {query: {active: 0}});
}

function addConnectMethod() {
	cmstore.fetch({
		query: {name: dijit.byId('addcmsel').value},
		onItem: addConnectMethod2
	});
}

function addConnectMethod2(item) {
	if(cmstore.getValue(item, 'autoprovisioned') == 0) {
		dojo.byId('autoconfirmcontent').innerHTML = cmstore.getValue(item, 'display');
		dijit.byId('autoconfirmdlg').show();
		return;
	}
	addConnectMethod3();
}

function addConnectMethod3() {
	dojo.byId('cmerror').innerHTML = '';
	dijit.byId('addcmbtn').attr('label', 'Working...');
	var data = {continuation: dojo.byId('addcmcont').value,
	            newid: dijit.byId('addcmsel').value};
	if(dijit.byId('conmethodrevid'))
		data.revid = dijit.byId('conmethodrevid').get('value');
	else
		data.revid = 0;
	RPCwrapper(data, addConnectMethodCB, 1);
}

function addConnectMethodCB(data, ioArgs) {
	if(data.items.error) {
		dijit.byId('addcmbtn').attr('label', 'Add Method');
		alert(data.items.msg);
		return;
	}
	cmstore.fetch({
		query: {name: data.items.newid},
		onItem: function(item) {
			cmstore.setValue(item, 'active', 1);
		}
	});
	dijit.byId('addcmsel').setStore(cmstore, '', {query: {active: 0}});
	dojo.byId('addcmcont').value = data.items.addcont;
	dojo.byId('remcmcont').value = data.items.remcont;
	dijit.byId('addcmbtn').attr('label', 'Add Method');
}

function remConnectMethod() {
	var obj = dojo.byId('curmethodsel');
	var cmids = new Array();
	for(var i = obj.options.length - 1; i >= 0; i--) {
		if(obj.options[i].selected)
			cmids.push(obj.options[i].value);
	}
	if(! cmids.length)
		return;
	if(cmids.length == obj.options.length) {
		dojo.byId('cmerror').innerHTML = 'There must be at least one item in Current Methods';
		setTimeout(function() {dojo.byId('cmerror').innerHTML = '';}, 20000);
		return;
	}
	var ids = cmids.join(',');
	dijit.byId('remcmbtn').attr('label', 'Working...');
	var data = {continuation: dojo.byId('remcmcont').value,
	            ids: ids};
	if(dijit.byId('conmethodrevid'))
		data.revid = dijit.byId('conmethodrevid').get('value');
	else
		data.revid = 0;
	RPCwrapper(data, remConnectMethodCB, 1);
}

function remConnectMethodCB(data, ioArgs) {
	if(dijit.byId('addcmsel').get('disabled')) {
		dijit.byId('addcmsel').set('disabled', false);
		dijit.byId('addcmbtn').set('disabled', false);
	}
	if(data.items.error) {
		dijit.byId('rembtn').attr('label', 'Remove Selected Methods');
		alert(data.items.msg);
		return;
	}
	var obj = dojo.byId('curmethodsel');
	for(var i = obj.options.length - 1; i >= 0; i--) {
		if(obj.options[i].selected) {
			cmstore.fetch({
				query: {name: obj.options[i].value},
				onItem: function(item) {
					cmstore.setValue(item, 'active', 0);
				}
			});
			obj.remove(i);
		}
	}
	dijit.byId('addcmsel').setStore(cmstore, '', {query: {active: 0}});
	dojo.byId('addcmcont').value = data.items.addcont;
	dojo.byId('remcmcont').value = data.items.remcont;
	updateConnectionMethodList();
	dijit.byId('remcmbtn').attr('label', 'Remove Selected Methods');
}

function updateConnectionMethodList() {
	var options = dojo.byId('curmethodsel').options;
	var items = new Array();
	var ids = new Array();
	for(var i = 0; i < options.length; i++) {
		items.push(options[i].text);
		ids.push(options[i].value);
	}
	dojo.byId('connectmethodlist').innerHTML = items.join('<br>');
	if(dojo.byId('connectmethodids'))
		dojo.byId('connectmethodids').value = ids.join(',');
}

function log10(x) {
	return Math.log(x) / Math.LN10;
}

function updateRevisionProduction(cont) {
   document.body.style.cursor = 'wait';
	RPCwrapper({continuation: cont}, generalCB);
}

function updateRevisionComments(id, cont) {
   document.body.style.cursor = 'wait';
	var data = {continuation: cont,
	            comments: dijit.byId(id).value};
	RPCwrapper(data, updateRevisionCommentsCB, 1);
}

function updateRevisionCommentsCB(data, ioArgs) {
	//var obj = dijit.byId('comments' + data.items.id);
	//obj.setValue(data.items.comments);
	document.body.style.cursor = 'default';
}

function deleteRevisions(cont, idlist) {
	var ids = idlist.split(',');
	var checkedids = new Array();
	for(var i = 0; i < ids.length; i++) {
		var id = ids[i];
		var obj = document.getElementById('chkrev' + id);
		var obj2 = document.getElementById('radrev' + id);
		if(obj.checked) {
			if(obj2.checked) {
				alert('You cannot delete the production revision.');
				return;
			}
			checkedids.push(id);
		}
	}
	if(checkedids.length == 0)
		return;
	checkedids = checkedids.join(',');
	var data = {continuation: cont,
	            checkedids: checkedids};
	RPCwrapper(data, deleteRevisionsCB, 1);
}

function deleteRevisionsCB(data, ioArgs) {
	if('status' in data.items && data.items.status == 'error') {
		dojo.byId('deletemsg').innerHTML = data.items.msg;
		return;
	}
	dijit.registry.filter(function(widget, index){return widget.id.match(/^comments/);}).forEach(function(widget) {widget.destroy();});
	var obj = document.getElementById('revisiondiv');
	obj.innerHTML = data.items.html;
	AJdojoCreate('revisiondiv');
}

function hideStartImageDlg() {
	dojo.byId('newimage').checked = true;
}

function hideUpdateImageDlg() {
	dojo.byId('newimage').checked = true;
	dojo.byId('updateimage').value = '';
	dojo.byId('previouscomments').innerHTML = '';
	dijit.byId('newcomments').reset();
}

function startImage(cont) {
	RPCwrapper({continuation: cont}, startImageCB, 1);
}

function startImageCB(data, ioArgs) {
	if(data.items.status == 'error') {
		alert(data.items.errmsg);
		return;
	}
	// configure add image dialog, extra work, but saves an AJAX call after selection
	resetEditResource();
	var methodids = new Array();
	var methods = new Array();
	for(var key in data.items.connectmethods) {
		if(isNaN(key))
			continue;
		methodids.push(key);
		methods.push(data.items.connectmethods[key]);
	}
	dojo.byId('connectmethodids').value = methodids.join(',');
	dojo.byId('connectmethodlist').innerHTML = methods.join('<br>');
	dijit.byId('owner').set('value', data.items.owner);
	dijit.byId('connectmethodttd').set('href', data.items.connectmethodurl);
	dojo.byId('addresourcecont').value = data.items.newcont;
	if(data.items.enableupdate == 1) {
		dojo.byId('updateimage').value = data.items.updatecont;
		dojo.byId('previouscomments').innerHTML = data.items.comments;
		dojo.byId('updateimage').disabled = '';
		dojo.removeClass('updateimagelabel', 'disabledlabel');
	}
	else {
		dojo.byId('updateimage').disabled = 'disabled';
		dojo.addClass('updateimagelabel', 'disabledlabel');
	}
	dijit.byId('addeditbtn').set('label', 'Create Image');
	dijit.byId('addeditbtn').set('disabled', false);
	dijit.byId('clickthroughDlgBtn').set('disabled', false);

	if(data.items.checkpoint) {
		dojo.addClass('imageendrescontent', 'hidden');
		dojo.removeClass('imagekeeprescontent', 'hidden');
	}
	else {
		dojo.removeClass('imageendrescontent', 'hidden');
		dojo.addClass('imagekeeprescontent', 'hidden');
	}

	// show selection dialog
	dijit.byId('startimagedlg').show();
}

function submitCreateUpdateImage() {
	if(dojo.byId('newimage').checked) {
		dijit.byId('addeditdlg').show();
		dijit.byId('startimagedlg').hide();
		return;
	}
	else if(dojo.byId('updateimage').checked) {
		//var data = {continuation: dojo.byId('updateimage').value};
		dijit.byId('updateimagedlg').show();
		dijit.byId('startimagedlg').hide();
		return;
	}
}

function submitUpdateImage() {
	var data = {continuation: dojo.byId('updateimage').value,
	            comments: dijit.byId('newcomments').value};
	RPCwrapper(data, updateImageCB, 1);
}

function updateImageCB(data, ioArgs) {
	if(data.items.status == 'error') {
		alert(data.items.errmsg);
		dijit.byId('updateimagedlg').hide();
		return;
	} else if(data.items.status == 'success') {
		if(data.items.action == 'clickthrough') {
			dojo.byId('updateimage').value = data.items.cont;
			dojo.byId('clickthroughDlgContent').innerHTML = data.items.agree;
			dijit.byId('clickthroughdlg').show();
			return;
		}
	}
	else if(data.items.status == 'noaccess') {
		alert('You must be the owner of the image to update it.');
		dijit.byId('updateimagedlg').hide();
		return;
	}
}

function clickThroughAgree() {
	if(dijit.byId('addeditdlg').open)
		saveResource();
	else if(dijit.byId('updateimagedlg').open)
		submitUpdateImageClickthrough();
}

function submitUpdateImageClickthrough() {
	var data = {continuation: dojo.byId('updateimage').value};
	RPCwrapper(data, submitUpdateImageClickthroughCB, 1);
}

function submitUpdateImageClickthroughCB(data, ioArgs) {
	if(data.items.status == 'noaccess') {
		alert('You must be the owner of the image to update it.');
		dijit.byId('updateimagedlg').hide();
		dijit.byId('clickthroughdlg').hide();
		return;
	}
	else if(data.items.status == 'error') {
		alert(data.items.errmsg);
		dijit.byId('updateimagedlg').hide();
		dijit.byId('clickthroughdlg').hide();
		return;
	}
	dijit.byId('updateimagedlg').hide();
	dijit.byId('clickthroughdlg').hide();
	resRefresh();
}
