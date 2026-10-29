-- Public-safe COUNTERFACTUAL model. NOT installed in original N-Questie.
-- Explicit source/mocks vs model separation: no client, frames, real data or fix.
local parentFile=assert(io.open("tests/compat/nq_part45_g08_original_orphan_child_epoch_contract.lua","rb"))
local parentText=assert(parentFile:read("*a"));parentFile:close()
local n=0
local function check(v,label) assert(v,label);n=n+1 end
check(parentText:find("local function newLedger()",1,true)~=nil,
  "R01_PARENT_COUNTERFACTUAL_LEDGER_PRESENT")
check(parentText:find("child.serial~=self.serial",1,true)~=nil,
  "R02_PREVIOUS_LEDGER_ONLY_CHECKS_SERIAL")

-- New strictly model-only ownership contract, not an alteration of original code.
-- unsafe switches are negative controls deliberately weakening just one guard.
local function registeredLedger(unsafe)
  unsafe=unsafe or {}
  local l={serial=0,current=nil,visible=0,readySignals=0,
    counts={COMPLETED=0,ABORTED=0,ERROR=0}}
  function l:terminal(owner,status)
    if owner~=self.current or owner.state~="PENDING" then return false end
    if status~="COMPLETED" and status~="ABORTED" and status~="ERROR" then
      return false
    end
    if status=="COMPLETED" and
      (not owner.parentFinished or owner.outstanding~=0) then return false end
    owner.state=status
    self.counts[status]=self.counts[status]+1
    if status=="COMPLETED" then self.readySignals=self.readySignals+1 end
    for child in pairs(owner.issued) do
      child.cancelled=true
      owner.issued[child]=nil
    end
    owner.registered=0
    owner.outstanding=0
    return true
  end
  function l:begin(label)
    if self.current and self.current.state=="PENDING" then
      assert(self:terminal(self.current,"ABORTED"))
    end
    self.serial=self.serial+1
    local owner={label=label,serial=self.serial,state="PENDING",
      parentFinished=false,outstanding=0,registered=0,issued={}}
    self.current=owner
    return owner
  end
  function l:child(owner,parentChild)
    if owner~=self.current or owner.state~="PENDING"
      or owner.parentFinished then return nil end
    if parentChild and (not owner.issued[parentChild]
      or parentChild.done or parentChild.cancelled) then return nil end
    local child={owner=owner,serial=owner.serial,done=false,
      cancelled=false,dependents=0,parent=parentChild}
    owner.issued[child]=true
    owner.registered=owner.registered+1
    owner.outstanding=owner.outstanding+1
    if parentChild then parentChild.dependents=parentChild.dependents+1 end
    return child
  end
  function l:publish(child)
    if type(child)~="table" or type(child.owner)~="table" then return false end
    local owner=child.owner
    if owner~=self.current or owner.state~="PENDING"
      or child.serial~=self.serial or child.done or child.cancelled
      or (not unsafe.noPublishMembership and not owner.issued[child])
      or (child.parent and not owner.issued[child.parent]) then return false end
    self.visible=self.visible+1
    return true
  end
  function l:childDone(child)
    if type(child)~="table" or type(child.owner)~="table" then return false end
    local owner=child.owner
    if owner~=self.current or owner.state~="PENDING"
      or child.serial~=self.serial or child.done or child.cancelled
      or (not unsafe.noDoneMembership and not owner.issued[child])
      or (child.dependents or 0)~=0 then return false end
    child.done=true
    if owner.issued[child] then
      owner.issued[child]=nil
      owner.registered=owner.registered-1
    end
    if child.parent then child.parent.dependents=child.parent.dependents-1 end
    owner.outstanding=owner.outstanding-1
    if owner.outstanding==0 and owner.parentFinished then
      assert(self:terminal(owner,"COMPLETED"))
    end
    return true
  end
  function l:parentDone(owner)
    if owner~=self.current or owner.state~="PENDING"
      or owner.parentFinished then return false end
    owner.parentFinished=true
    if owner.outstanding==0 then
      return self:terminal(owner,"COMPLETED")
    end
    return true
  end
  function l:error(owner)
    return self:terminal(owner,"ERROR")
  end
  return l
end

-- Positive nested owner/child/grandchild path.
local v=registeredLedger()
local owner=v:begin("A")
check(owner.serial==1 and owner.state=="PENDING",
  "R03_ACTIVE_OWNER_PENDING")
local root=v:child(owner)
local sibling=v:child(owner)
local grandchild=v:child(owner,root)
check(root and sibling and grandchild,"R04_THREE_AUTHENTIC_CHILDREN")
check(owner.registered==3 and owner.outstanding==3,
  "R05_OUTSTANDING_EQUALS_REGISTRY")
check(root.dependents==1 and grandchild.parent==root,
  "R06_DESCENDANT_PARENT_IDENTITY")
check(v:publish(root) and v:publish(grandchild),
  "R07_REGISTERED_ROOT_AND_DESCENDANT_WRITE")
check(not v:childDone(root),"R08_PARENT_CHILD_CANNOT_FINISH_BEFORE_DESCENDANT")
check(owner.outstanding==3 and owner.registered==3,
  "R09_PREMATURE_CHILD_DONE_NO_COUNT_LOSS")
check(v:parentDone(owner),"R10_RESET_PARENT_FINISHES_BUT_CHILDREN_WAIT")
check(owner.state=="PENDING" and v.readySignals==0,
  "R11_CHILDREN_BLOCK_FALSE_READY")
check(not v:child(owner),"R12_NO_NEW_CHILD_AFTER_PARENT_FINISH")
check(not v:child(owner,root),"R13_NO_DESCENDANT_AFTER_PARENT_FINISH")
check(v:childDone(grandchild),"R14_GRANDCHILD_COMPLETES_FIRST")
check(root.dependents==0 and owner.outstanding==2 and owner.registered==2,
  "R15_REGISTRY_COUNTERS_AFTER_GRANDCHILD")
check(not v:publish(grandchild) and not v:childDone(grandchild),
  "R16_COMPLETED_GRANDCHILD_NO_REPLAY")
check(v:childDone(root),"R17_ROOT_CHILD_COMPLETES_AFTER_DESCENDANT")
check(owner.outstanding==1 and owner.registered==1
  and owner.state=="PENDING","R18_SIBLING_STILL_PREVENTS_READY")
check(v:childDone(sibling),"R19_FINAL_SIBLING_COMPLETES")
check(owner.state=="COMPLETED" and v.readySignals==1,
  "R20_SUCCESS_SIGNAL_EXACTLY_ONCE")
check(owner.registered==0 and owner.outstanding==0,
  "R21_SUCCESS_CHILD_REGISTRY_CLEANED")
check(not v:publish(root) and not v:publish(sibling),
  "R22_COMPLETED_OWNER_BLOCKS_WRITES")
check(not v:parentDone(owner) and not v:error(owner),
  "R23_COMPLETED_OWNER_TERMINAL_NONREENTRANT")
check(v.counts.COMPLETED==1,"R24_NORMAL_COMPLETION_CENSUS")

-- Fake ticket matching the current owner and serial must NEVER publish,
-- decrement outstanding, or fake completion. Older model permitted both.
local s=registeredLedger()
local live=s:begin("LIVE")
local real=s:child(live)
check(real~=nil and live.registered==1,"R25_REAL_CHILD_REGISTERED")
check(s:parentDone(live) and live.state=="PENDING",
  "R26_PARENT_WAITS_FOR_REGISTERED_CHILD")
local counterfeit={owner=live,serial=live.serial,done=false,
  cancelled=false,dependents=0}
check(not s:publish(counterfeit),"R27_SAME_OWNER_SERIAL_UNREGISTERED_WRITE_REJECTED")
check(not s:childDone(counterfeit),"R28_UNREGISTERED_COMPLETION_REJECTED")
check(live.state=="PENDING" and live.outstanding==1
  and live.registered==1 and s.readySignals==0,
  "R29_UNREGISTERED_TICKET_CANNOT_FALSE_COMPLETE")
check(not s:childDone({owner=live,serial=live.serial-1,done=false}),
  "R30_OLD_SERIAL_CANNOT_COMPLETE_LIVE_OWNER")
check(not s:publish({owner=live,serial=live.serial+1,done=false}),
  "R31_FUTURE_SERIAL_CANNOT_WRITE")
local forgedOwner={label=live.label,serial=live.serial,state="PENDING",
  issued={},outstanding=1,registered=1}
check(not s:publish({owner=forgedOwner,serial=live.serial,done=false}),
  "R32_LABEL_SERIAL_CLONE_OWNER_REJECTED")
check(not s:childDone({owner=forgedOwner,serial=live.serial,done=false}),
  "R33_LABEL_SERIAL_CLONE_CANNOT_COMPLETE")
check(live.outstanding==1 and live.registered==1 and s.visible==0,
  "R34_FORGERIES_PRESERVE_INVARIANT")
check(s:childDone(real) and live.state=="COMPLETED",
  "R35_REAL_CHILD_COMPLETES_WITHOUT_FORGED_TICKET")
check(s.readySignals==1 and s.counts.COMPLETED==1,
  "R36_REAL_COMPLETION_EXACTLY_ONCE")
check(not s:publish(counterfeit) and not s:childDone(counterfeit),
  "R37_UNREGISTERED_TICKET_STILL_REJECTED_AFTER_TERMINAL")

-- New A -> B -> A epoch cancellation with retained nested descendants.
local aba=registeredLedger()
local oldA=aba:begin("A")
local aParent=aba:child(oldA)
local aGrand=aba:child(oldA,aParent)
check(oldA.outstanding==2 and oldA.registered==2,
  "R38_OLD_A_NESTED_CHILDREN")
local b=aba:begin("B")
check(oldA.state=="ABORTED" and oldA.outstanding==0
  and oldA.registered==0,"R39_SUPERSEDED_OWNER_REGISTRY_CLEARED")
check(aParent.cancelled and aGrand.cancelled,
  "R40_ABORT_CASCADES_DESCENDANTS")
check(not aba:publish(aGrand) and not aba:childDone(aGrand),
  "R41_ABORTED_DESCENDANT_NEVER_WRITES_OR_COMPLETES")
local newA=aba:begin("A")
check(b.state=="ABORTED" and newA.serial~=oldA.serial,
  "R42_ABA_NEW_OWNER_NEW_EPOCH")
check(not aba:child(oldA) and not aba:parentDone(oldA),
  "R43_SUPERSEDED_OLD_A_CANNOT_RESUME")
local newAChild=aba:child(newA)
check(newAChild~=nil and aba:publish(newAChild),
  "R44_NEW_A_CHILD_CAN_WRITE")
check(aba:parentDone(newA) and newA.state=="PENDING",
  "R45_NEW_A_AWAITS_CHILD")
check(aba:childDone(newAChild) and newA.state=="COMPLETED",
  "R46_NEW_A_AUTHENTIC_CHILD_RELEASE")
check(aba.counts.ABORTED==2 and aba.counts.COMPLETED==1
  and aba.readySignals==1,"R47_ABA_TERMINAL_ACCOUNTING")

-- ERROR and invalid terminal states never signal READY.
local err=registeredLedger()
local broken=err:begin("ERR")
local e1=err:child(broken)
local e2=err:child(broken,e1)
check(not err:terminal(broken,"COMPLETED"),
  "R48_CANNOT_FORCE_READY_WITH_UNFINISHED_CHILDREN")
check(not err:terminal(broken,"BOGUS"),
  "R49_UNKNOWN_TERMINAL_REJECTED")
check(err:error(broken) and broken.state=="ERROR",
  "R50_ERROR_TERMINATES_PARENT")
check(broken.outstanding==0 and broken.registered==0
  and e1.cancelled and e2.cancelled,
  "R51_ERROR_DETACHES_ALL_REGISTERED_DESCENDANTS")
check(not err:publish(e1) and not err:childDone(e2),
  "R52_ERROR_CHILD_WRITES_AND_COMPLETION_REJECTED")
check(not err:error(broken) and not err:parentDone(broken),
  "R53_ERROR_TERMINAL_ONCE")
check(err.readySignals==0 and err.counts.ERROR==1
  and err.counts.COMPLETED==0,"R54_ERROR_NEVER_FALSE_READY")
local nextOwner=err:begin("RECOVERY")
check(nextOwner.serial==2 and nextOwner.state=="PENDING",
  "R55_NEW_OWNER_CAN_START_AFTER_ERROR")
check(err:parentDone(nextOwner) and nextOwner.state=="COMPLETED",
  "R56_ZERO_CHILD_NORMAL_COMPLETION")
check(err.readySignals==1 and err.counts.ERROR==1
  and err.counts.COMPLETED==1,"R57_RECOVERY_NO_DOUBLE_READY")

-- Mutation/negative controls: deliberately weakened test-only copies should
-- accept exact forged witnesses, showing both membership checks matter.
local wrongPublish=registeredLedger({noPublishMembership=true})
local wpOwner=wrongPublish:begin("BADP")
local wpReal=wrongPublish:child(wpOwner)
check(wpReal~=nil,"R58_PUBLISH_MUTANT_REAL_CHILD_EXISTS")
check(wrongPublish:publish({owner=wpOwner,serial=wpOwner.serial,done=false}),
  "R59_PUBLISH_MEMBERSHIP_MUTANT_ACCEPTS_UNREGISTERED")
check(wrongPublish.visible==1 and wpOwner.registered==1,
  "R60_MUTANT_UNREGISTERED_WRITE_WITNESSED")
local wrongDone=registeredLedger({noDoneMembership=true})
local wdOwner=wrongDone:begin("BADD")
local wdReal=wrongDone:child(wdOwner)
check(wdReal~=nil and wrongDone:parentDone(wdOwner),
  "R61_DONE_MUTANT_PARENT_WAITS_REAL_CHILD")
check(wrongDone:childDone({owner=wdOwner,serial=wdOwner.serial,
  done=false,dependents=0}),
  "R62_CHILD_DONE_MEMBERSHIP_MUTANT_ACCEPTS_FORGERY")
check(wdOwner.state=="COMPLETED" and wrongDone.readySignals==1
  and wdReal.cancelled,"R63_MUTANT_FALSE_READY_BEFORE_REAL_CHILD")
check(not wrongDone:childDone(wdReal),
  "R64_FALSE_READY_MUTANT_CANCELED_REAL_CHILD")
check(wdOwner.outstanding==0 and wdOwner.registered==0,
  "R65_MUTANT_TERMINAL_CLEANUP_HIDES_EARLY_COMPLETION")

assert(n==65,"PART46_REGISTERED_CHILD_CENSUS:"..n)
print("PUBLIC G08 PART46 REGISTERED DESCENDANT LEDGER: 65/65 PASS")
print("PUBLIC G08 PART46 MODEL: exact child registration blocks unregistered publish and false childDone; nested descendants wait; ABORT/ERROR clear registry without READY.")
print("PUBLIC G08 PART46 NEGATIVE CONTROLS: deliberately weakened publish/childDone membership models accept forged tickets; model-only, never original addon or native client.")
