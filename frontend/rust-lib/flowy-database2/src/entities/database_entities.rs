use collab::core::collab_state::SyncState;
use collab_database::rows::RowId;
use collab_database::views::DatabaseLayout;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::{ErrorCode, FlowyError};

use lib_infra::validator_fn::required_not_empty_str;
use serde::{Deserialize, Serialize};
use validator::Validate;

use crate::entities::parser::NotEmptyStr;
use crate::entities::{DatabaseLayoutPB, FieldIdPB, RowMetaPB};
use crate::services::database::CreateDatabaseViewParams;

/// [DatabasePB] describes how many fields and blocks the grid has
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct DatabasePB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub fields: Vec<FieldIdPB>,

  #[pb(index = 3)]
  pub rows: Vec<RowMetaPB>,

  #[pb(index = 4)]
  pub layout_type: DatabaseLayoutPB,
}

#[derive(ProtoBuf, Default)]
pub struct CreateDatabaseViewPayloadPB {
  #[pb(index = 1)]
  pub name: String,

  #[pb(index = 2)]
  pub view_id: String,

  #[pb(index = 3)]
  pub layout_type: DatabaseLayoutPB,
}

impl TryInto<CreateDatabaseViewParams> for CreateDatabaseViewPayloadPB {
  type Error = FlowyError;

  fn try_into(self) -> Result<CreateDatabaseViewParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseViewIdIsEmpty)?;
    Ok(CreateDatabaseViewParams {
      name: self.name,
      view_id: view_id.0,
      layout_type: self.layout_type.into(),
    })
  }
}

#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct DatabaseIdPB {
  #[pb(index = 1)]
  pub value: String,
}

impl AsRef<str> for DatabaseIdPB {
  fn as_ref(&self) -> &str {
    &self.value
  }
}

#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct RepeatedDatabaseIdPB {
  #[pb(index = 1)]
  pub value: Vec<DatabaseIdPB>,
}

#[derive(Clone, ProtoBuf, Default, Debug, Validate)]
pub struct DatabaseViewIdPB {
  #[pb(index = 1)]
  #[validate(custom(function = "required_not_empty_str"))]
  pub value: String,
}

impl AsRef<str> for DatabaseViewIdPB {
  fn as_ref(&self) -> &str {
    &self.value
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct MoveFieldPayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub from_field_id: String,

  #[pb(index = 3)]
  pub to_field_id: String,
}

#[derive(Clone)]
pub struct MoveFieldParams {
  pub view_id: String,
  pub from_field_id: String,
  pub to_field_id: String,
}

impl TryInto<MoveFieldParams> for MoveFieldPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<MoveFieldParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseViewIdIsEmpty)?;
    let from_field_id =
      NotEmptyStr::parse(self.from_field_id).map_err(|_| ErrorCode::InvalidParams)?;
    let to_field_id = NotEmptyStr::parse(self.to_field_id).map_err(|_| ErrorCode::InvalidParams)?;
    Ok(MoveFieldParams {
      view_id: view_id.0,
      from_field_id: from_field_id.0,
      to_field_id: to_field_id.0,
    })
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct MoveRowPayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub from_row_id: String,

  #[pb(index = 3)]
  pub to_row_id: String,
}

pub struct MoveRowParams {
  pub view_id: String,
  pub from_row_id: RowId,
  pub to_row_id: RowId,
}

impl TryInto<MoveRowParams> for MoveRowPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<MoveRowParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseViewIdIsEmpty)?;
    let from_row_id = NotEmptyStr::parse(self.from_row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;
    let to_row_id = NotEmptyStr::parse(self.to_row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;

    Ok(MoveRowParams {
      view_id: view_id.0,
      from_row_id: RowId::from(from_row_id.0),
      to_row_id: RowId::from(to_row_id.0),
    })
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct MoveGroupRowPayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub from_row_id: String,

  #[pb(index = 3)]
  pub to_group_id: String,

  #[pb(index = 4, one_of)]
  pub to_row_id: Option<String>,

  #[pb(index = 5)]
  pub from_group_id: String,
}

pub struct MoveGroupRowParams {
  pub view_id: String,
  pub from_row_id: RowId,
  pub from_group_id: String,
  pub to_group_id: String,
  pub to_row_id: Option<RowId>,
}

impl TryInto<MoveGroupRowParams> for MoveGroupRowPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<MoveGroupRowParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseViewIdIsEmpty)?;
    let from_group_id =
      NotEmptyStr::parse(self.from_group_id).map_err(|_| ErrorCode::GroupIdIsEmpty)?;
    let to_group_id =
      NotEmptyStr::parse(self.to_group_id).map_err(|_| ErrorCode::GroupIdIsEmpty)?;

    Ok(MoveGroupRowParams {
      view_id: view_id.0,
      to_group_id: to_group_id.0,
      from_group_id: from_group_id.0,
      from_row_id: RowId::from(self.from_row_id),
      to_row_id: self.to_row_id.map(RowId::from),
    })
  }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct DatabaseMetaPB {
  #[pb(index = 1)]
  pub database_id: String,

  #[pb(index = 2)]
  pub view_id: String,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedDatabaseDescriptionPB {
  #[pb(index = 1)]
  pub items: Vec<DatabaseMetaPB>,
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct DatabaseGroupIdPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub group_id: String,
}

pub struct DatabaseGroupIdParams {
  pub view_id: String,
  pub group_id: String,
}

impl TryInto<DatabaseGroupIdParams> for DatabaseGroupIdPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<DatabaseGroupIdParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseViewIdIsEmpty)?;
    let group_id = NotEmptyStr::parse(self.group_id).map_err(|_| ErrorCode::GroupIdIsEmpty)?;
    Ok(DatabaseGroupIdParams {
      view_id: view_id.0,
      group_id: group_id.0,
    })
  }
}
#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct DatabaseLayoutMetaPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub layout: DatabaseLayoutPB,
}

#[derive(Clone, Debug)]
pub struct DatabaseLayoutMeta {
  pub view_id: String,
  pub layout: DatabaseLayout,
}

impl TryInto<DatabaseLayoutMeta> for DatabaseLayoutMetaPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<DatabaseLayoutMeta, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseViewIdIsEmpty)?;
    let layout = self.layout.into();
    Ok(DatabaseLayoutMeta {
      view_id: view_id.0,
      layout,
    })
  }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct DatabaseSyncStatePB {
  #[pb(index = 1)]
  pub value: DatabaseSyncState,
}

#[derive(Debug, Default, ProtoBuf_Enum, PartialEq, Eq, Clone, Copy)]
pub enum DatabaseSyncState {
  #[default]
  InitSyncBegin = 0,
  InitSyncEnd = 1,
  Syncing = 2,
  SyncFinished = 3,
}

impl From<SyncState> for DatabaseSyncStatePB {
  fn from(value: SyncState) -> Self {
    let value = match value {
      SyncState::InitSyncBegin => DatabaseSyncState::InitSyncBegin,
      SyncState::InitSyncEnd => DatabaseSyncState::InitSyncEnd,
      SyncState::Syncing => DatabaseSyncState::Syncing,
      SyncState::SyncFinished => DatabaseSyncState::SyncFinished,
    };
    Self { value }
  }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct DatabaseSnapshotStatePB {
  #[pb(index = 1)]
  pub new_snapshot_id: i64,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedDatabaseSnapshotPB {
  #[pb(index = 1)]
  pub items: Vec<DatabaseSnapshotPB>,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct DatabaseSnapshotPB {
  #[pb(index = 1)]
  pub snapshot_id: i64,

  #[pb(index = 2)]
  pub snapshot_desc: String,

  #[pb(index = 3)]
  pub created_at: i64,

  #[pb(index = 4)]
  pub data: Vec<u8>,
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct RemoveCoverPayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub row_id: String,
}

pub struct RemoveCoverParams {
  pub view_id: String,
  pub row_id: RowId,
}

impl TryInto<RemoveCoverParams> for RemoveCoverPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<RemoveCoverParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseViewIdIsEmpty)?;
    let row_id = NotEmptyStr::parse(self.row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;

    Ok(RemoveCoverParams {
      view_id: view_id.0,
      row_id: RowId::from(row_id.0),
    })
  }
}

#[derive(Default, ProtoBuf, Clone, Debug)]
pub struct RepeatedCustomPromptPB {
  #[pb(index = 1)]
  pub items: Vec<CustomPromptPB>,
}

#[derive(Default, ProtoBuf, Clone, Debug)]
pub struct CustomPromptPB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3)]
  pub content: String,

  #[pb(index = 4)]
  pub example: String,

  #[pb(index = 5)]
  pub category: String,
}

#[derive(Default, ProtoBuf, Clone, Debug, Serialize, Deserialize, Validate)]
pub struct CustomPromptDatabaseConfigPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub title_field_id: String,

  #[pb(index = 3)]
  pub content_field_id: String,

  #[pb(index = 4, one_of)]
  pub example_field_id: Option<String>,

  #[pb(index = 5, one_of)]
  pub category_field_id: Option<String>,
}
