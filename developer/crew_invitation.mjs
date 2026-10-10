import {randomBytes,createHash} from 'node:crypto';
import {StoreError} from './store.mjs';

const messages={
 AUTH_REQUIRED:'로그인 후 초대를 확인해 주세요.',
 INVITATION_FORBIDDEN:'이 크루의 계정 연결을 관리할 권한이 없어요.',
 INVITATION_UNAVAILABLE:'초대가 만료되었거나 취소됐어요. 관리자에게 새 초대를 요청해 주세요.',
 INVITATION_USED:'이미 사용한 초대예요. 관리자에게 연결 상태를 확인해 주세요.',
 CREW_UNAVAILABLE:'연결할 크루를 찾지 못했어요.',
 CREW_CHANGED:'크루 상태가 변경됐어요. 관리자가 연결 상태를 확인하고 새로 초대해 주세요.',
 ALREADY_JOINED:'이미 이 매장에 연결된 계정이에요. 관리자에게 연결할 크루를 확인해 주세요.',
 REVISION_CONFLICT:'최신 내용과 차이가 있어 저장하지 못했어요. 입력한 내용은 유지했어요.',
 USE_UNLINK:'수락한 초대는 계정 연결 해제에서 처리해 주세요.',
};
export function invitationHash(code){
 if(typeof code!=='string')throw new StoreError('초대 코드를 입력해 주세요.');
 const normalized=code.trim().replace(/[-\s]/g,'').toUpperCase();
 if(!/^[A-F0-9]{24}$/.test(normalized))throw new StoreError('초대 코드 24자리를 확인해 주세요.');
 return createHash('sha256').update(normalized).digest('hex');
}

export function createCrewInvitationHandler({rest}) {
 return async({request,user})=>{
  if(request.method!=='POST'||!request.headers.get('content-type')?.startsWith('application/json'))throw new StoreError('JSON 요청이 필요해요.',415);
  const raw=await request.text();if(raw.length>6000)throw new StoreError('초대 요청이 너무 커요.',413);
  let input;try{input=JSON.parse(raw);}catch{throw new StoreError('초대 요청을 확인해 주세요.');}
  if(!input||Array.isArray(input)||!['create','list','preview','accept','revoke','unlink'].includes(input.action))throw new StoreError('초대 요청을 확인해 주세요.');
  if(input.action==='accept'&&input.confirm!==true)throw new StoreError('매장과 크루 정보를 확인하고 연결을 수락해 주세요.');
  const uuid=/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i;
  const scoped=!['preview','accept'].includes(input.action);
  if(scoped&&!uuid.test(input.workspaceId??''))throw new StoreError('매장을 선택해 주세요.');
  if(['create','unlink'].includes(input.action)&&(typeof input.tapperId!=='string'||input.tapperId.length>100||!input.tapperId))throw new StoreError('등록된 크루를 선택해 주세요.');
  if(input.action==='revoke'&&!uuid.test(input.inviteId??''))throw new StoreError('초대를 선택해 주세요.');
  if(['create','revoke','unlink'].includes(input.action)&&!Number.isSafeInteger(input.revision))throw new StoreError('최신 매장 정보를 불러와 주세요.');
  const code=input.action==='create'?randomBytes(12).toString('hex').toUpperCase():null;
  const result=await rest('rpc/tap2work_crew_invitation',{method:'POST',body:JSON.stringify({
   p_action:input.action,p_user_id:user.id,p_workspace_id:scoped?input.workspaceId:null,p_tapper_id:input.tapperId??null,p_invite_id:input.inviteId??null,
   p_token_hash:code?invitationHash(code):['preview','accept'].includes(input.action)?invitationHash(input.code):null,p_expected_revision:input.revision??null,
  })});
  if(result?.errorCode)throw new StoreError(messages[result.errorCode]??'초대 상태를 다시 확인해 주세요.',result.status??400,result.errorCode);
  // Raw one-time codes exist only in this response, never stored in DB/logs.
  return code?{...result,code:code.match(/.{4}/g).join('-'),link:`https://tap2.work/?invite=${code}`} : result;
 };
}
