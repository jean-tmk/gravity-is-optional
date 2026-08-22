/* Compiled browser adapter for gravity_engine.sql. SQL remains the rule source of truth. */
const $=(selector,root=document)=>root.querySelector(selector);
const $$=(selector,root=document)=>[...root.querySelectorAll(selector)];

const SQL_RULES=[
  {id:1,slug:"standard-down",name:"Standard Down / Unpopular",angle:90,strength:62,glyph:"↓",color:"#d9ff45",message:"THE FLOOR HAS BEEN NOTIFIED.",sql:"SELECT vector FROM gravity_rules WHERE slug = 'standard-down';"},
  {id:2,slug:"ceiling-day",name:"Ceiling Appreciation Day",angle:270,strength:58,glyph:"↑",color:"#ff6257",message:"THE CEILING HAS ACCEPTED NEW RESPONSIBILITIES.",sql:"UPDATE orientation SET angle = 270 WHERE room = 'office';"},
  {id:3,slug:"eastward-office",name:"Everything Files East",angle:0,strength:74,glyph:"←",color:"#62c8ff",message:"ALL PAPERWORK NOW FALLS TOWARD YESTERDAY.",sql:"SELECT apply_vector(0, 74, 'eastward-office');"},
  {id:4,slug:"diagonal-lunch",name:"Diagonal Lunch Break",angle:135,strength:52,glyph:"↘",color:"#b8a1ff",message:"LUNCH WILL ARRIVE AT A FORTY-FIVE DEGREE ANGLE.",sql:"CALL rotate_reality(135, 'until further notice');"},
  {id:5,slug:"soft-left",name:"A Gentle Lean Left",angle:180,strength:31,glyph:"→",color:"#ffd0a8",message:"THE ROOM IS LEANING, BUT POLITELY.",sql:"SELECT * FROM vectors WHERE force < 0.35 ORDER BY doubt;"},
  {id:6,slug:"microgravity",name:"Zero-G Filing Hour",angle:90,strength:0,glyph:"0G",color:"#8ce2c4",message:"DOWN HAS LEFT AN OUT-OF-OFFICE REPLY.",sql:"DELETE FROM gravity WHERE certainty = 'unnecessary';"}
];

const OBJECTS=[
  {label:"LOST KEY",mass:1.2,color:"#d9ff45",image:"assets/objects/lost-key.webp"},
  {label:"MONDAY",mass:2.4,color:"#ff6257",image:"assets/objects/monday.webp"},
  {label:"SMALL MOON",mass:3.2,color:"#62c8ff",image:"assets/objects/small-moon.webp"},
  {label:"PAPER CLIP",mass:.7,color:"#b8a1ff",image:"assets/objects/paper-clip.webp"},
  {label:"ONE IDEA",mass:1.5,color:"#ffd0a8",image:"assets/objects/one-idea.webp"},
  {label:"LUNCH",mass:2.1,color:"#8ce2c4",image:"assets/objects/lunch.webp"}
];
const OBJECT_IMAGES=new Map(OBJECTS.map(object=>{const image=new Image();image.decoding="async";image.src=object.image;return [object.image,image]}));

const canvas=$("#gravityCanvas"),ctx=canvas.getContext("2d"),windowEl=$("#physicsWindow");
const state={angle:90,strength:62,paused:false,sound:true,objects:[],drag:null,docked:new Set(),mission:"dock",orbitTime:0,rainScore:0,last:performance.now()};
let audio;

function playTone(frequency=220,duration=.12,type="triangle",volume=.055){
  if(!state.sound)return;
  try{
    const Audio=window.AudioContext||window.webkitAudioContext;
    audio=audio||new Audio();
    const make=()=>{const oscillator=audio.createOscillator(),gain=audio.createGain(),now=audio.currentTime+.01;oscillator.type=type;oscillator.frequency.setValueAtTime(frequency,now);gain.gain.setValueAtTime(volume,now);gain.gain.exponentialRampToValueAtTime(.001,now+duration);oscillator.connect(gain).connect(audio.destination);oscillator.start(now);oscillator.stop(now+duration)};
    audio.state==="suspended"?audio.resume().then(make):make();
  }catch(error){}
}
function chord(notes){notes.forEach((note,index)=>setTimeout(()=>playTone(note,.13,"triangle",.04),index*55))}

function resize(){const box=windowEl.getBoundingClientRect(),scale=Math.min(devicePixelRatio||1,2);canvas.width=Math.round(box.width*scale);canvas.height=Math.round(box.height*scale);canvas.style.width=box.width+"px";canvas.style.height=box.height+"px";ctx.setTransform(scale,0,0,scale,0,0);state.width=box.width;state.height=box.height;if(!state.objects.length)resetObjects()}
function resetObjects(){state.docked.clear();state.objects=OBJECTS.map((item,index)=>({ ...item,asset:OBJECT_IMAGES.get(item.image),x:80+(index%3)*145+(Math.random()-.5)*26,y:125+Math.floor(index/3)*125+(Math.random()-.5)*24,vx:(Math.random()-.5)*.5,vy:(Math.random()-.5)*.5,w:86,h:86,rotation:(Math.random()-.5)*.15,spin:(Math.random()-.5)*.002,docked:false}));updateMission()}
function directionVector(){const radians=state.angle*Math.PI/180;return {x:-Math.cos(radians),y:Math.sin(radians)}}
function dockBounds(){return {x:state.width*.71,y:state.height*.79,w:state.width*.25,h:state.height*.17}}

function roundedRect(x,y,w,h,r){ctx.beginPath();ctx.roundRect(x,y,w,h,r)}
function drawGrid(){ctx.save();ctx.strokeStyle="rgba(255,255,255,.075)";ctx.lineWidth=1;for(let x=0;x<state.width;x+=38){ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,state.height);ctx.stroke()}for(let y=0;y<state.height;y+=38){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(state.width,y);ctx.stroke()}ctx.restore()}
function drawObject(object,index){ctx.save();ctx.translate(object.x,object.y);ctx.rotate(object.rotation);ctx.shadowColor="rgba(7,3,25,.5)";ctx.shadowBlur=14;ctx.shadowOffsetX=5;ctx.shadowOffsetY=7;if(object.asset?.complete&&object.asset.naturalWidth){const ratio=Math.min(object.w/object.asset.naturalWidth,object.h/object.asset.naturalHeight);const width=object.asset.naturalWidth*ratio,height=object.asset.naturalHeight*ratio;ctx.drawImage(object.asset,-width/2,-height/2-7,width,height)}else{ctx.fillStyle=object.color;ctx.beginPath();ctx.arc(0,-7,object.w*.28,0,Math.PI*2);ctx.fill()}ctx.shadowColor="transparent";ctx.rotate(-object.rotation);ctx.fillStyle="rgba(247,240,223,.94)";ctx.strokeStyle=object.color;ctx.lineWidth=1;roundedRect(-40,object.h/2-13,80,19,9);ctx.fill();ctx.stroke();ctx.fillStyle="#24164f";ctx.font="500 6.5px 'DM Mono'";ctx.textAlign="center";ctx.textBaseline="middle";ctx.fillText(`${object.label} / ${object.mass.toFixed(1)}`,0,object.h/2-3);ctx.restore()}
function drawOrbit(){if(state.mission!=="orbit")return;ctx.save();ctx.translate(state.width*.5,state.height*.48);ctx.strokeStyle="rgba(217,255,69,.5)";ctx.setLineDash([5,9]);ctx.beginPath();ctx.ellipse(0,0,170,105,state.orbitTime*.00008,0,Math.PI*2);ctx.stroke();ctx.fillStyle="#d9ff45";ctx.font="500 7px 'DM Mono'";ctx.fillText("MAINTAIN ORBIT / 12 SEC",-70,-122);ctx.restore()}
function drawRain(){if(state.mission!=="rain")return;ctx.save();ctx.strokeStyle="rgba(98,200,255,.7)";for(let i=0;i<28;i++){const x=(i*83+state.orbitTime*.16)%Math.max(1,state.width+150)-100,y=(i*47)%state.height;ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(x+26,y+3);ctx.stroke()}ctx.restore()}

function physics(delta){
  if(state.paused)return;
  const vector=directionVector(),gravity=state.strength*.000012*delta;
  const dock=dockBounds();
  state.objects.forEach((object,index)=>{
    if(state.drag===index||object.docked)return;
    object.vx+=vector.x*gravity;object.vy+=vector.y*gravity;
    object.vx*=.998;object.vy*=.998;object.x+=object.vx*delta;object.y+=object.vy*delta;object.rotation+=object.spin*delta;
    const halfW=object.w/2,halfH=object.h/2;
    if(object.x<halfW){object.x=halfW;object.vx=Math.abs(object.vx)*.72;object.spin+=(Math.random()-.5)*.003;playCollision(object)}
    if(object.x>state.width-halfW){object.x=state.width-halfW;object.vx=-Math.abs(object.vx)*.72;object.spin+=(Math.random()-.5)*.003;playCollision(object)}
    if(object.y<halfH){object.y=halfH;object.vy=Math.abs(object.vy)*.72;playCollision(object)}
    if(object.y>state.height-halfH){object.y=state.height-halfH;object.vy=-Math.abs(object.vy)*.72;playCollision(object)}
    if(object.x>dock.x&&object.x<dock.x+dock.w&&object.y>dock.y&&object.y<dock.y+dock.h){object.docked=true;object.vx=object.vy=0;object.x=dock.x+28+(state.docked.size%3)*42;object.y=dock.y+34+Math.floor(state.docked.size/3)*42;object.w=42;object.h=42;state.docked.add(index);chord([330,440,550]);updateMission()}
  });
  if(state.mission==="orbit")state.strength<23?state.orbitTime+=delta:state.orbitTime=0;
  if(state.mission==="rain")(state.angle<12||state.angle>348)?state.rainScore=Math.min(100,state.rainScore+delta*.008):state.rainScore=0;
}
function playCollision(object){const now=performance.now();if(!object.lastSound||now-object.lastSound>220){playTone(100+object.mass*38,.06,"square",.018);object.lastSound=now}}
function frame(time){const delta=Math.min(32,time-state.last||16);state.last=time;ctx.clearRect(0,0,state.width,state.height);drawGrid();drawOrbit();drawRain();physics(delta);state.objects.forEach(drawObject);if(state.mission!=="dock")updateMission();requestAnimationFrame(frame)}

function pointerPosition(event){const box=canvas.getBoundingClientRect();return {x:event.clientX-box.left,y:event.clientY-box.top}}
canvas.addEventListener("pointerdown",event=>{const point=pointerPosition(event);for(let index=state.objects.length-1;index>=0;index--){const object=state.objects[index];if(Math.abs(point.x-object.x)<object.w/2&&Math.abs(point.y-object.y)<object.h/2&&!object.docked){state.drag=index;canvas.setPointerCapture(event.pointerId);object.vx=object.vy=0;playTone(190,.08);break}}});
canvas.addEventListener("pointermove",event=>{if(state.drag===null)return;const point=pointerPosition(event),object=state.objects[state.drag];object.vx=(point.x-object.x)*.012;object.vy=(point.y-object.y)*.012;object.x=point.x;object.y=point.y});
canvas.addEventListener("pointerup",event=>{if(state.drag!==null)playTone(260,.08);state.drag=null;canvas.releasePointerCapture?.(event.pointerId)});

function applyRule(rule){state.angle=rule.angle;state.strength=rule.strength;$("#force").value=rule.strength;$("#forceOutput").textContent=rule.strength+"%";$("#forceReadout").textContent=rule.strength+"%";$("#fieldReadout").textContent=rule.strength===0?"0G":rule.angle+"°";$("#directionGlyph").textContent=rule.glyph;$("#fieldMessage").textContent=rule.message;$("#ruleName").textContent=rule.name.toUpperCase();$("#ruleSql").textContent=rule.sql;$$('[data-direction]').forEach(button=>button.classList.toggle("active",Number(button.dataset.direction)===rule.angle&&rule.strength>0));$("#microgravity").classList.toggle("active",rule.strength===0);$$('.rule-card').forEach(card=>card.classList.toggle("active",card.dataset.rule===rule.slug));const radians=rule.angle*Math.PI/180,distance=rule.strength===0?0:72,demo=$("#ruleDemonstrator");demo?.style.setProperty("--test-x",`${-Math.cos(radians)*distance}px`);demo?.style.setProperty("--test-y",`${Math.sin(radians)*distance}px`);demo?.style.setProperty("--test-rotate",`${rule.strength===0?0:rule.angle-90}deg`);demo?.style.setProperty("--rule-accent",rule.color);if($("#cabinetRuleName"))$("#cabinetRuleName").textContent=rule.name;if($("#cabinetRuleMessage"))$("#cabinetRuleMessage").textContent=rule.message;if($("#cabinetVector"))$("#cabinetVector").textContent=rule.glyph;chord([170,230,310])}
function setDirection(angle){const glyphs={0:"←",45:"↙",90:"↓",135:"↘",180:"→",225:"↗",270:"↑",315:"↖"},rule={angle,strength:Number($("#force").value),glyph:glyphs[angle],message:"ORIENTATION UPDATED / PLEASE ADJUST EXPECTATIONS.",name:`Custom Vector / ${angle} Degrees`,sql:`UPDATE gravity_rules SET active = 1 WHERE angle = ${angle};`};applyRule(rule)}
function renderRules(){$("#ruleCards").innerHTML=SQL_RULES.map((rule,index)=>`<button class="rule-card" type="button" data-rule="${rule.slug}" style="--card:${rule.color}"><span>RULE ${String(index+1).padStart(2,"0")} / ${rule.angle}°</span><i>${rule.glyph}</i><b>${rule.name}</b><small>${rule.message}</small></button>`).join("");$$('.rule-card').forEach(card=>card.onclick=()=>applyRule(SQL_RULES.find(rule=>rule.slug===card.dataset.rule)))}

const MISSIONS={
  dock:{kicker:"ASSIGNMENT 01 / MISPLACED MATTER",title:"Deliver six things to the docking bay.",copy:"Change the direction of gravity until every object crosses the striped bay. There is no correct down—only useful momentum."},
  orbit:{kicker:"ASSIGNMENT 02 / ADMINISTRATIVE ORBIT",title:"Keep the office in microgravity for twelve seconds.",copy:"Reduce the field below 23%. The filing system would like to experience one complete, uninterrupted orbit."},
  rain:{kicker:"ASSIGNMENT 03 / SIDEWAYS WEATHER",title:"Make the rain fall completely sideways.",copy:"Point gravity due east and maintain the contradiction until the weather office gives up."}
};
function updateMission(){let value=0,label="",status="INCOMPLETE / PROMISING";$("#dockReadout").textContent=`${state.docked.size}/6`;if(state.mission==="dock"){value=state.docked.size/6*100;label=`${state.docked.size} OF 6 DOCKED`;if(state.docked.size===6)status="COMPLETE / PHYSICS IMPRESSED"}if(state.mission==="orbit"){value=Math.min(100,state.orbitTime/12000*100);label=`${Math.floor(state.orbitTime/1000)} OF 12 SECONDS`;if(value>=100)status="COMPLETE / ORBIT FILED"}if(state.mission==="rain"){value=state.rainScore;label=`${Math.floor(value)}% SIDEWAYS`;if(value>=100)status="COMPLETE / FORECAST DENIED"}$("#missionProgressLabel").textContent=label;$("#missionProgressBar").style.width=value+"%";$("#missionStatus").textContent=status;if(value>=100&&!state.completed){state.completed=true;chord([330,440,550,660])}}
function setMission(name){state.mission=name;state.completed=false;state.orbitTime=0;state.rainScore=0;const mission=MISSIONS[name];$("#missionKicker").textContent=mission.kicker;$("#missionTitle").textContent=mission.title;$("#missionCopy").textContent=mission.copy;$$('[data-mission]').forEach(button=>button.setAttribute("aria-selected",String(button.dataset.mission===name)));updateMission();playTone(280,.15)}

$$('[data-direction]').forEach(button=>button.onclick=()=>setDirection(Number(button.dataset.direction)));
$("#microgravity").onclick=()=>applyRule(SQL_RULES.find(rule=>rule.slug==="microgravity"));
$("#force").oninput=event=>{state.strength=Number(event.target.value);$("#forceOutput").textContent=state.strength+"%";$("#forceReadout").textContent=state.strength+"%";$("#ruleName").textContent="CUSTOM FIELD / UNVERIFIED";$("#ruleSql").textContent=`UPDATE gravity_rules SET strength = ${state.strength} WHERE active = 1;`};
$("#gust").onclick=()=>{state.objects.forEach(object=>{if(!object.docked){object.vx+=(Math.random()-.5)*.7;object.vy+=(Math.random()-.5)*.7;object.spin+=(Math.random()-.5)*.006}});$("#fieldMessage").textContent="A SMALL BUT DETERMINED GUST HAS BEEN RELEASED.";chord([110,160,210])};
$("#freeze").onclick=event=>{state.paused=!state.paused;event.currentTarget.querySelector("b").textContent=state.paused?"UNFREEZE THE FIELD":"FREEZE THE FIELD";$("#fieldMessage").textContent=state.paused?"PHYSICS PAUSED / TAKE YOUR TIME.":"PHYSICS HAS RELUCTANTLY RESUMED.";playTone(state.paused?120:320,.18,"square")};
$("#shuffle").onclick=()=>{resetObjects();$("#fieldMessage").textContent="THE SAME SIX SPECIMENS HAVE BEEN FILED INCORRECTLY AGAIN.";chord([260,310,370])};
$("#fieldReset").onclick=()=>{resetObjects();playTone(180,.22,"sawtooth")};
$$('[data-mission]').forEach(button=>button.onclick=()=>setMission(button.dataset.mission));
$("#soundToggle").onclick=event=>{state.sound=!state.sound;event.currentTarget.textContent=state.sound?"SOUND / ON":"SOUND / OFF";event.currentTarget.setAttribute("aria-pressed",String(state.sound));if(state.sound)chord([220,330,440])};
$("#viewAppliedRule").onclick=()=>{$("#laboratory").scrollIntoView({behavior:"smooth",block:"start"});setTimeout(()=>state.objects.forEach(object=>{if(!object.docked){object.vx+=(Math.random()-.5)*.35;object.vy+=(Math.random()-.5)*.35}}),500)};

renderRules();resize();addEventListener("resize",resize);applyRule(SQL_RULES[0]);requestAnimationFrame(frame);
