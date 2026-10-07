import {createCatalogAdminHandler} from '../../../developer/catalog_admin.mjs';
Deno.serve(createCatalogAdminHandler({
 url:Deno.env.get('SUPABASE_URL'),
 serviceKey:Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'),
 origins:(Deno.env.get('TAP2WORK_ORIGINS')??'https://tap2.work,https://www.tap2.work').split(','),
}));
