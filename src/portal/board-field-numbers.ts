// Compare decimal values before and after JSON-number conversion; never round an actual entry silently.
function decimalIdentity(value:string){
 const match=/^([+-]?)(\d+(?:\.\d*)?|\.\d+)(?:e([+-]?\d+))?$/i.exec(value);
 if(!match)throw Error('Enter an actual valid number.');
 const digits=match[2].replace('.','').replace(/^0+/,''),fraction=match[2].split('.')[1]?.length||0;
 if(!digits)return '0';
 const coefficient=digits.replace(/0+$/,''),exponent=BigInt(match[3]||0)-BigInt(fraction)+BigInt(digits.length-coefficient.length);
 return (match[1]==='-'?'-':'')+coefficient+'e'+exponent;
}
export function actualBoardNumber(raw:string){
 const value=raw.trim(),number=Number(value);
 if(!value||value.length>100||!Number.isFinite(number)||decimalIdentity(value)!==decimalIdentity(String(number)))throw Error('Number would lose precision. Use a Text field to preserve exact digits; no value was saved.');
 return number;
}
