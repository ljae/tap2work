import {test} from 'node:test';
import assert from 'node:assert/strict';
import {normalizeBreaks,operatingSegments} from '../business_breaks.mjs';
test('overnight business break intersects common and separate part windows',()=>{
 const days={1:[{start:'22:00',end:'05:00'}]};
 const pause={start:'01:00',end:'02:00'};
 assert.deepEqual(normalizeBreaks(days,{1:pause},'06:00'),{1:pause});
 assert.deepEqual(operatingSegments(days[1][0],pause,'06:00'),[{start:'22:00',end:'01:00',suffix:''},{start:'02:00',end:'05:00',suffix:'-after-break',dayOffset:1}]);
 assert.deepEqual(operatingSegments({start:'01:00',end:'02:00'},pause,'06:00'),[]);
 assert.deepEqual(operatingSegments({start:'01:30',end:'03:00'},pause,'06:00'),[{start:'02:00',end:'03:00',suffix:'',dayOffset:1}]);
});
test('overnight break also works with legacy midnight boundary',()=>{
 const band={start:'22:00',end:'05:00'}, pause={start:'01:00',end:'02:00'};
 assert.deepEqual(normalizeBreaks({1:[band]},{1:pause},'00:00'),{1:pause});
 assert.equal(operatingSegments(band,pause,'00:00').length,2);
});
