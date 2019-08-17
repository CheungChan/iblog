---
title: xadmin实现textarea代码高亮
key: xadmin_textarea_highlight
layout: article
date: '2019-08-15 11:51:00'
tags: 技术 python
typora-root-url: ../../iblog
---

 [**adminx.py**](https://gist.github.com/CheungChan/f79b2a158e8337c71523ab0268d2d38b#file-adminx-py)

```python
from .widgets import YaraRulesetWidget

class YaraRulesetForm(ModelForm):
    ruleset_raw_string = CharField(widget=YaraRulesetWidget)
    
class YaraRulesetAdmin:
    form = YaraRulesetForm
```

[**widgets.py**](https://gist.github.com/CheungChan/f79b2a158e8337c71523ab0268d2d38b#file-widgets-py)

```python
# -*- coding: utf-8 -*-
__author__ = '陈章'
__date__ = '2019-07-16 12:21'

import os

from django import forms


class YaraRulesetWidget(forms.Textarea):

    def render(self, name, value, attrs=None, renderer=None):
        jS = """
<link href="/static/highlight-within-textarea/jquery.highlight-within-textarea.css" rel="stylesheet">
<script src="/static/highlight-within-textarea/jquery.highlight-within-textarea.js"></script>
<script src="/static/hunting/yara_ruleset.js"></script>
<style>
        .hwt-container {
            background-color: #f8f9fa;
        }
        .hwt-content {
            width: 833px;
            height: 500px;
            color: transparent;
            caret-color: black; /* Edge ignores this, but luckily doesn't need it */
        }
        .hwt-highlights {
            color: black !important;
        }
        .hwt-input:focus {
            outline-color: #495057;
        }
        .hwt-content mark {
             color: #8B008B;
            background-color: transparent;
        }
        .hwt-content mark.red {
            color: #DC143C;
        }
        .hwt-content mark.blue {
            color: #00BFFF;
        }
        .hwt-content mark.yellow {
            color: #F4A460;
        }
        .hwt-content mark.green {
            color: #008080;
        }
</style>
    """
        html = """
<textarea name="ruleset_raw_string" cols="70" rows="40" class="form-control" required id="id_ruleset_raw_string">
   ##ruleset_raw_string
</textarea> 
        """
        html = html.replace("##ruleset_raw_string", value)
        return jS + html
```

[**yara_ruleset.js**](https://gist.github.com/CheungChan/f79b2a158e8337c71523ab0268d2d38b#file-yara_ruleset-js)

```js
$(document).ready(function(){
    function match_rule_name(input) {
        let r = /rule\s*(.*)\s*{/gi;
        var l = [];
        var match = r.exec(input);
        while (match != null) {
            let s = match[1];
            l.push(s);
            match = r.exec(input);
        }
        return l || false;

    }

    function match_keyword(input) {
        let keywords = [/rule\s/gi, /meta:\s/gi, /strings:\s/gi, /condition:\s/gi, /\sat\s/gi, /\sand\s/gi, /\sof\s/gi, /\scontains\s/gi,];
        var l = [];
        for (r of keywords) {
            var match = r.exec(input);
            while (match != null) {
                let s = match[0];
                l.push(s);
                match = r.exec(input);
            }
        }
        return l || false;
    }

    function match_double_qoute_string(input) {
        var l = [];
        r = /"(?:\\.|[^\\"])*"/gi;
        var match = r.exec(input);
        while (match != null) {
            let s = match[0];
            l.push(s);
            match = r.exec((input))
        }
        return l || false;
    }

    let hightlightOptions = {
        highlight: [

            // 关键字
            {
                highlight: match_keyword,
            },
            // rule name
            {
                highlight: match_rule_name,
                className: 'blue',
            },
            // 不在字符串里的数字
            {
                highlight: /[^"^\w]\d+[^"^\w]/gi,
                className: "green",
            },

            // 双引号
            {
                highlight: match_double_qoute_string,
                className: 'red',
            },
            // 注释
            {
                highlight: /\/\/[^\n]*/gi,
                className: 'yellow',
            },
        ]
    };
    $("#id_ruleset_raw_string").highlightWithinTextarea(hightlightOptions);
    $("#id_ruleset_raw_string").highlightWithinTextarea("update");
    });
```





 [**highlight-within-textarea__jquery.highlight-within-textarea.css**](https://gist.github.com/CheungChan/f79b2a158e8337c71523ab0268d2d38b#file-highlight-within-textarea__jquery-highlight-within-textarea-css)

```css
.hwt-container {
	display: inline-block;
	position: relative;
	overflow: hidden !important;
	-webkit-text-size-adjust: none !important;
}

.hwt-backdrop {
	position: absolute !important;
	top: 0 !important;
	right: -99px !important;
	bottom: 0 !important;
	left: 0 !important;
	padding-right: 99px !important;
	overflow-x: hidden !important;
	overflow-y: auto !important;
}

.hwt-highlights {
	width: auto !important;
	height: auto !important;
	border-color: transparent !important;
	white-space: pre-wrap !important;
	word-wrap: break-word !important;
	color: transparent !important;
	overflow: hidden !important;
}

.hwt-input {
	display: block !important;
	position: relative !important;
	margin: 0;
	padding: 0;
	border-radius: 0;
	font: inherit;
	overflow-x: hidden !important;
	overflow-y: auto !important;
}

.hwt-content {
	border: 1px solid;
	background: none transparent !important;
}

.hwt-content mark {
	padding: 0 !important;
	color: inherit;
}
```

[**highlight-within-textarea__jquery.highlight-within-textarea.js**](https://gist.github.com/CheungChan/f79b2a158e8337c71523ab0268d2d38b#file-highlight-within-textarea__jquery-highlight-within-textarea-js)

{% raw %}

```js
/*
 * highlight-within-textarea
 *
 * @author  Will Boyd
 * @github  https://github.com/lonekorean/highlight-within-textarea
 */

(function($) {
	let ID = 'hwt';

	let HighlightWithinTextarea = function($el, config) {
		this.init($el, config);
	};

	HighlightWithinTextarea.prototype = {
		init: function($el, config) {
			this.$el = $el;

			// backwards compatibility with v1 (deprecated)
			if (this.getType(config) === 'function') {
				config = { highlight: config };
			}

			if (this.getType(config) === 'custom') {
				this.highlight = config;
				this.generate();
			} else {
				console.error('valid config object not provided');
			}
		},

		// returns identifier strings that aren't necessarily "real" JavaScript types
		getType: function(instance) {
			let type = typeof instance;
			if (!instance) {
				return 'falsey';
			} else if (Array.isArray(instance)) {
				if (instance.length === 2 && typeof instance[0] === 'number' && typeof instance[1] === 'number') {
					return 'range';
				} else {
					return 'array';
				}
			} else if (type === 'object') {
				if (instance instanceof RegExp) {
					return 'regexp';
				} else if (instance.hasOwnProperty('highlight')) {
					return 'custom';
				}
			} else if (type === 'function' || type === 'string') {
				return type;
			}

			return 'other';
		},

		generate: function() {
			this.$el
				.addClass(ID + '-input ' + ID + '-content')
				.on('input.' + ID, this.handleInput.bind(this))
				.on('scroll.' + ID, this.handleScroll.bind(this));

			this.$highlights = $('<div>', { class: ID + '-highlights ' + ID + '-content' });

			this.$backdrop = $('<div>', { class: ID + '-backdrop' })
				.append(this.$highlights);

			this.$container = $('<div>', { class: ID + '-container' })
				.insertAfter(this.$el)
				.append(this.$backdrop, this.$el) // moves $el into $container
				.on('scroll', this.blockContainerScroll.bind(this));

			this.browser = this.detectBrowser();
			switch (this.browser) {
				case 'firefox':
					this.fixFirefox();
					break;
				case 'ios':
					this.fixIOS();
					break;
			}

			// plugin function checks this for success
			this.isGenerated = true;

			// trigger input event to highlight any existing input
			this.handleInput();
		},

		// browser sniffing sucks, but there are browser-specific quirks to handle
		// that are not a matter of feature detection
		detectBrowser: function() {
			let ua = window.navigator.userAgent.toLowerCase();
			if (ua.indexOf('firefox') !== -1) {
				return 'firefox';
			} else if (!!ua.match(/msie|trident\/7|edge/)) {
				return 'ie';
			} else if (!!ua.match(/ipad|iphone|ipod/) && ua.indexOf('windows phone') === -1) {
				// Windows Phone flags itself as "like iPhone", thus the extra check
				return 'ios';
			} else {
				return 'other';
			}
		},

		// Firefox doesn't show text that scrolls into the padding of a textarea, so
		// rearrange a couple box models to make highlights behave the same way
		fixFirefox: function() {
			// take padding and border pixels from highlights div
			let padding = this.$highlights.css([
				'padding-top', 'padding-right', 'padding-bottom', 'padding-left'
			]);
			let border = this.$highlights.css([
				'border-top-width', 'border-right-width', 'border-bottom-width', 'border-left-width'
			]);
			this.$highlights.css({
				'padding': '0',
				'border-width': '0'
			});

			this.$backdrop
				.css({
					// give padding pixels to backdrop div
					'margin-top': '+=' + padding['padding-top'],
					'margin-right': '+=' + padding['padding-right'],
					'margin-bottom': '+=' + padding['padding-bottom'],
					'margin-left': '+=' + padding['padding-left'],
				})
				.css({
					// give border pixels to backdrop div
					'margin-top': '+=' + border['border-top-width'],
					'margin-right': '+=' + border['border-right-width'],
					'margin-bottom': '+=' + border['border-bottom-width'],
					'margin-left': '+=' + border['border-left-width'],
				});
		},

		// iOS adds 3px of (unremovable) padding to the left and right of a textarea,
		// so adjust highlights div to match
		fixIOS: function() {
			this.$highlights.css({
				'padding-left': '+=3px',
				'padding-right': '+=3px'
			});
		},

		handleInput: function() {
			let input = this.$el.val();
			let ranges = this.getRanges(input, this.highlight);
			let unstaggeredRanges = this.removeStaggeredRanges(ranges);
			let boundaries = this.getBoundaries(unstaggeredRanges);
			this.renderMarks(boundaries);
		},

		getRanges: function(input, highlight) {
			let type = this.getType(highlight);
			switch (type) {
				case 'array':
					return this.getArrayRanges(input, highlight);
				case 'function':
					return this.getFunctionRanges(input, highlight);
				case 'regexp':
					return this.getRegExpRanges(input, highlight);
				case 'string':
					return this.getStringRanges(input, highlight);
				case 'range':
					return this.getRangeRanges(input, highlight);
				case 'custom':
					return this.getCustomRanges(input, highlight);
				default:
					if (!highlight) {
						// do nothing for falsey values
						return [];
					} else {
						console.error('unrecognized highlight type');
					}
			}
		},

		getArrayRanges: function(input, arr) {
			let ranges = arr.map(this.getRanges.bind(this, input));
			return Array.prototype.concat.apply([], ranges);
		},

		getFunctionRanges: function(input, func) {
			return this.getRanges(input, func(input));
		},

		getRegExpRanges: function(input, regex) {
			let ranges = [];
			let match;
			while (match = regex.exec(input), match !== null) {
				ranges.push([match.index, match.index + match[0].length]);
				if (!regex.global) {
					// non-global regexes do not increase lastIndex, causing an infinite loop,
					// but we can just break manually after the first match
					break;
				}
			}
			return ranges;
		},

		getStringRanges: function(input, str) {
			let ranges = [];
			let inputLower = input.toLowerCase();
			let strLower = str.toLowerCase();
			let index = 0;
			while (index = inputLower.indexOf(strLower, index), index !== -1) {
				ranges.push([index, index + strLower.length]);
				index += strLower.length;
			}
			return ranges;
		},

		getRangeRanges: function(input, range) {
			return [range];
		},

		getCustomRanges: function(input, custom) {
			let ranges = this.getRanges(input, custom.highlight);
			if (custom.className) {
				ranges.forEach(function(range) {
					// persist class name as a property of the array
					if (range.className) {
						range.className = custom.className + ' ' + range.className;
					} else {
						range.className = custom.className;
					}
				});
			}
			return ranges;
		},

		// prevent staggered overlaps (clean nesting is fine)
		removeStaggeredRanges: function(ranges) {
			let unstaggeredRanges = [];
			ranges.forEach(function(range) {
				let isStaggered = unstaggeredRanges.some(function(unstaggeredRange) {
					let isStartInside = range[0] > unstaggeredRange[0] && range[0] < unstaggeredRange[1];
					let isStopInside = range[1] > unstaggeredRange[0] && range[1] < unstaggeredRange[1];
					return isStartInside !== isStopInside; // xor
				});
				if (!isStaggered) {
					unstaggeredRanges.push(range);
				}
			});
			return unstaggeredRanges;
		},

		getBoundaries: function(ranges) {
			let boundaries = [];
			ranges.forEach(function(range) {
				boundaries.push({
					type: 'start',
					index: range[0],
					className: range.className
				});
				boundaries.push({
					type: 'stop',
					index: range[1]
				});
			});

			this.sortBoundaries(boundaries);
			return boundaries;
		},

		sortBoundaries: function(boundaries) {
			// backwards sort (since marks are inserted right to left)
			boundaries.sort(function(a, b) {
				if (a.index !== b.index) {
					return b.index - a.index;
				} else if (a.type === 'stop' && b.type === 'start') {
					return 1;
				} else if (a.type === 'start' && b.type === 'stop') {
					return -1;
				} else {
					return 0;
				}
			});
		},

		renderMarks: function(boundaries) {
			let input = this.$el.val();
			boundaries.forEach(function(boundary, index) {
				let markup;
				if (boundary.type === 'start') {
					markup = '{{hwt-mark-start|' + index + '}}';
				} else {
					markup = '{{hwt-mark-stop}}';
				}
				input = input.slice(0, boundary.index) + markup + input.slice(boundary.index);
			});

			// this keeps scrolling aligned when input ends with a newline
			input = input.replace(/\n(\{\{hwt-mark-stop\}\})?$/, '\n\n$1');

			// encode HTML entities
			input = input.replace(/</g, '&lt;').replace(/>/g, '&gt;');

			if (this.browser === 'ie') {
				// IE/Edge wraps whitespace differently in a div vs textarea, this fixes it
				input = input.replace(/ /g, ' <wbr>');
			}

			// replace start tokens with opening <mark> tags with class name
			input = input.replace(/\{\{hwt-mark-start\|(\d+)\}\}/g, function(match, submatch) {
				var className = boundaries[+submatch].className;
				if (className) {
					return '<mark class="' + className + '">';
				} else {
					return '<mark>';
				}
			});

			// replace stop tokens with closing </mark> tags
			input = input.replace(/\{\{hwt-mark-stop\}\}/g, '</mark>');

			this.$highlights.html(input);
		},

		handleScroll: function() {
			let scrollTop = this.$el.scrollTop();
			this.$backdrop.scrollTop(scrollTop);

			// Chrome and Safari won't break long strings of spaces, which can cause
			// horizontal scrolling, this compensates by shifting highlights by the
			// horizontally scrolled amount to keep things aligned
			let scrollLeft = this.$el.scrollLeft();
			this.$backdrop.css('transform', (scrollLeft > 0) ? 'translateX(' + -scrollLeft + 'px)' : '');
		},

		// in Chrome, page up/down in the textarea will shift stuff within the
		// container (despite the CSS), this immediately reverts the shift
		blockContainerScroll: function() {
			this.$container.scrollLeft(0);
		},

		destroy: function() {
			this.$backdrop.remove();
			this.$el
				.unwrap()
				.removeClass(ID + '-text ' + ID + '-input')
				.off(ID)
				.removeData(ID);
		},
	};

	// register the jQuery plugin
	$.fn.highlightWithinTextarea = function(options) {
		return this.each(function() {
			let $this = $(this);
			let plugin = $this.data(ID);

			if (typeof options === 'string') {
				if (plugin) {
					switch (options) {
						case 'update':
							plugin.handleInput();
							break;
						case 'destroy':
							plugin.destroy();
							break;
						default:
							console.error('unrecognized method string');
					}
				} else {
					console.error('plugin must be instantiated first');
				}
			} else {
				if (plugin) {
					plugin.destroy();
				}
				plugin = new HighlightWithinTextarea($this, options);
				if (plugin.isGenerated) {
					$this.data(ID, plugin);
				}
			}
		});
	};
})(jQuery);
```

{% endraw %}