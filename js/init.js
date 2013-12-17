define(function(require, exports, module) {
	var $ = require('jquery');
	$(function() {
		var $b = $('body');
		$b.addClass('container');

		var $codes = $('pre code');
		if($codes.length) {
			require.async('hljs', function(hljs) {
				$codes.each(function(i, e) {hljs.highlightBlock(e)});
			});
		}
	});
});